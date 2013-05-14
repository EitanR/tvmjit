#! nqp

# test optional arguments and parameters

plan(3);

sub f1 ($x, $y!, $z?) {
  $x;
}
say('ok ', f1(1, 2), ' # optional args ignorable');
say('ok ', f1(2, 2, 2), ' # optional args passable');

sub f2 ($x?, $y?) { 'ok 3 # only optional args'; }
say(f2());
