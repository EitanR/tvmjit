#!./parrot nqp.pbc

# while, until statements

plan(6);

my $a; my $sum;

$a := 1; $sum := 0;
while $a != 10 {
    $sum := $sum + $a;
    $a := $a + 1;
}
ok($sum == 45, 'basic while loop test');

$a := 1; $sum := 0;
$sum := $sum + $a++ while $a < 10;
ok($sum == 45, 'basic while statement modifier');

$a := 1; $sum := 0;
until $a == 10 {
    $sum := $sum + $a;
    $a := $a + 1;
}
ok($sum == 45, 'basic until loop test');

$a := 1; $sum := 0;
$sum := $sum + $a++ until $a > 9;
ok($sum == 45, 'basic until statement modifier');

$a := 1; $sum := 0;
while $a != 1 {
    $sum := 99;
    $a := 1;
}
ok($sum == 0, 'while loop exits initial false immediately');

$a := 1; $sum := 0;
until $a == 1 {
    $sum := 99;
    $a := 1;
}
ok($sum == 0, 'until loop exits initial true immediately');

