module ulib.vector;

struct Vector(T) {
    T[] data;
    size_t length;

    bool append(T value) {
        if (!data) {
            auto data_ = kalloc!T();
            if (!data_.has()) {
                return false;
            }
            data = data_.get();
        }
        if (length >= data.length) {

        }
        data[length++] = value;
        return true;
    }
}
