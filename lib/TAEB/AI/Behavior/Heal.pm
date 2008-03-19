#!/usr/bin/env perl
package TAEB::AI::Behavior::Heal;
use TAEB::OO;
extends 'TAEB::AI::Behavior';

sub prepare {
    my $self = shift;

    if (TAEB->hp * 2 <= TAEB->maxhp) {
        my $spell = TAEB->find_castable("healing")
                 || TAEB->find_castable("extra healing");
        if ($spell) {
            $self->do(cast => spell => $spell, direction => ".");
            $self->currently("Casting heal at myself.");
            return 100;
        }

        # we've probably been writing Elbereth a bunch, so find a healing potion
        if (TAEB->hp * 3 < TAEB->maxhp) {
            my $potion = TAEB->find_item("potion of healing")
                      || TAEB->find_item("potion of extra healing")
                      || TAEB->find_item("potion of full healing");
            if ($potion) {
                $self->do(quaff => from => $potion);
                $self->currently("Quaffing a $potion");
                return 90;
            }
        }
    }

    # now casual healing
    if (TAEB->hp * 3 / 2 <= TAEB->maxhp) {
        if (TAEB->power >= 20) {
            if (my $spell = TAEB->find_castable("healing")) {
                $self->do(cast => spell => $spell, direction => ".");
                $self->currently("Casting heal at myself.");
                return 100;
            }
        }
    }

    return 0;
}

sub pickup {
    my $self = shift;
    my $item = shift;

    for (map { "potion of $_" } 'healing', 'extra healing', 'full healing') {
        return 1 if $item->identity eq $_;
    }

    return;
}

sub urgencies {
    return {
       100 => "casting a healing spell",
        90 => "quaffing a potion of healing, extra healing, or full healing",
    },
}

make_immutable;
no Moose;

1;

