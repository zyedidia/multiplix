module ulib.list;

import kernel.alloc;

struct List(T) {
    struct Node {
        T val;
        Node* next;
        Node* prev;
    }

    Node* front;
    Node* back;
    size_t length;

    void push_back(Node* n) {
        n.next = null;
        n.prev = back;
        if (back != null) {
            back.next = n;
        } else {
            front = n;
        }
        back = n;
        length++;
    }

    void push_front(Node* n) {
        n.next = front;
        n.prev = null;
        if (front != null) {
            front.prev = n;
        } else {
            back = n;
        }
        front = n;
        length++;
    }

    private Node* push(alias fn)(ref T val) {
        Node* n = knew!(Node)();
        if (!n) {
            return null;
        }
        n.val = val;
        fn(n);
        return n;
    }

    Node* push_back(ref T val) {
        return push!(push_back)(val);
    }

    Node* push_front(ref T val) {
        return push!(push_front)(val);
    }

    Node* pop_front() {
        Node* f = front;
        remove(f);
        return f;
    }

    Node* pop_back() {
        Node* b = back;
        remove(b);
        return b;
    }

    void remove(Node* n) {
        if (n.next != null) {
            n.next.prev = n.prev;
        } else {
            back = n.prev;
        }
        if (n.prev != null) {
            n.prev.next = n.next;
        } else {
            front = n.next;
        }
        length--;
    }

    int opApply(scope int delegate(ref Node*) dg) {
        Node* n = front;
        while (n) {
            int r = dg(n);
            if (r) return r;
            n = n.next;
        }
        return 0;
    }
}
