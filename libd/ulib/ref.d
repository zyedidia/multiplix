module ulib.ref;

// non-null reference
struct Ref(T) {
    alias PT = T*;
    private PT payload;
    @disable this();

    this(PT t) {
        payload = t;
    }

    inout(PT) get_payload() inout {
        return payload;
    }

    alias get_payload this;
}
