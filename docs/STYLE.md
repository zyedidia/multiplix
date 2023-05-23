# Multiplix style guide

Multiplix uses a style that is different from the standard D style. Here are
some of the key guidelines we try to adhere to:

---

Naming guidelines:

* Functions should be `snake_case`.
* Variables should be `snake_case`.
* Manifest constants should be `snake_case`.
* Structs should be `UpperCamelCase`.
* Enums should be `UpperCamelCase`.

---

Curly braces for opening functions/if statements/loops should be on the same
line as the defining statement.

```d
void foo() {
    // code...
}
```

---

Templates should be avoided if possible and only used in moderation. Some cases
require the use of templates, but in many cases templates can be avoided by
using function pointers, function overloading, or specializing a type for the
situation. Functions/types should only be made generic if multiple occurrences
of it are actually needed, not just to write code as generically as possible.

---

Case statements within a switch should not be indented. Example:

```d
switch (foo) {
case 1:
    // code...
case 2:
    // code...
}
```

---

`shared` should only be used for objects of type `Spinlock`, `SpinGuard(T)`,
or `PerCpu(T)`. Otherwise `__gshared` should be used.

---

Except in specific cases, `alias this` should be avoided.

---

`alias` functions should be avoided.

---

Imports should list the exact values they import, or use an alias import.

---

Imports should appear at the top of the file, or may appear at the top of a
function if they are only used within that function.

---

`usize` should be used instead of `size_t`.

---

In general, code should use `printf` instead of `println` for printing
formatted values.

---

Classes, interfaces, exceptions, module info (module constructors/destructors),
and runtime type information should not be used.
