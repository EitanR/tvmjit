#! nqp

# class inheritance

plan(3);

class ABC {
    method foo() {
        say('ok 1');
    }

    method bar() {
        say('ok 3');
    }
}

class XYZ is ABC {
    method foo() {
        say('ok 2');
    }
}


my $abc := ABC.new();
my $xyz := XYZ.new();

$abc.foo();
$xyz.foo();
$xyz.bar();

