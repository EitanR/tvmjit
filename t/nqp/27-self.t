#! nqp

plan(5);

class Foo {
    has $!abc;

    method foo() { $!abc := 1; $!abc };

    method uno() {
        self.foo();
    };

    method des() {
        if 1 {
            return self.foo();
        }
        0;
    };

    method tres($a) {
        if 1 {
            return self.foo();
        }
        0;
    };

    method quat() {
        for (2,3) -> $a {
            ok($a + $!abc, 'Can access attribute within lexical block');
        }
        1;
    }
};

ok(Foo.new.uno, "Can access self within method");
ok(Foo.new.des, "Can access self within sub-block");
ok(Foo.new.tres(42), "Can access self within method with signature");

Foo.new.quat;
