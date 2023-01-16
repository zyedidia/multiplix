module ulib.reference;

// Value of type T that must be initialized
struct Init(T) {
    private T payload;
    @disable this();

    this(T t) {
        payload = t;
    }

    inout(T) get_payload() inout {
        return payload;
    }

    alias get_payload this;
}

// non-null reference
alias Ref(T) = Init!(T*);
