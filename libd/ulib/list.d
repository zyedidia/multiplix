module ulib.list;

struct List(T) {
    struct Node(T) {
        T val;
        Node!(T)* next;
        Node!(T)* prev;
    }

    Node!(T)* front;
    Node!(T)* back;

    private void push_back(Node!(T)* n) {
        n.next = null;
        n.prev = back;
        if (back != null) {
            back.next = n;
        } else {
            front = n;
        }
        back = n;
    }

    private void push_front(Node!(T)* n) {
        n.next = front;
        n.prev = null;
        if (front != null) {
            front.Prev = n;
        } else {
            back = n;
        }
        front = n;
    }
}
