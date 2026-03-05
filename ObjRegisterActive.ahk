/*
    ObjRegisterActive(Object, CLSID, Flags:=0)

        Registers an object as the active object for a given class ID.
        Converted to AHK v2.

    Object:
            Any AutoHotkey object.
    CLSID:
            A GUID or ProgID of your own making.
            Pass an empty string to revoke (unregister) the object.
    Flags:
            One of the following values:
              0 (ACTIVEOBJECT_STRONG)
              1 (ACTIVEOBJECT_WEAK)
            Defaults to 0.
*/
ObjRegisterActive(Object, CLSID, Flags:=0) {
    static cookieJar := Map()
    if (!CLSID) {
        if cookieJar.Has(ObjPtr(Object)) && (cookie := cookieJar[ObjPtr(Object)]) != ""
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
        cookieJar.Delete(ObjPtr(Object))
        return
    }
    if cookieJar.Has(ObjPtr(Object))
        throw Error("Object is already registered", -1)
    _clsid := Buffer(16, 0)
    if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", _clsid)) < 0
        throw Error("Invalid CLSID", -1, CLSID)
    cookie := 0
    hr := DllCall("oleaut32\RegisterActiveObject"
        , "ptr", ObjPtr(Object), "ptr", _clsid, "uint", Flags, "uint*", &cookie
        , "uint")
    if hr < 0
        throw Error(Format("Error 0x{:x}", hr), -1)
    cookieJar[ObjPtr(Object)] := cookie
}
