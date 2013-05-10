#! nqp

# check comments

say('1..6');

#Comment preceding
say("ok 1");

say("ok 2"); #Comment following

#say("not ok 3");
#          say("not ok 4");

{ say('ok 3'); } # comment
{ say('ok 4'); }

=begin comment
say("not ok 7");

say("not ok 8");
=end comment

say("ok 5");

=begin comment
=end comment
say("ok 6");


