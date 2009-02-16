package TAEB::AI::Behavioral::Behavior::Equip;
use TAEB::OO;
use TAEB::Spoilers::Combat;
extends 'TAEB::AI::Behavioral::Behavior';

sub _rate_armor {
    my $self = shift;
    my $item = shift;

    return 0 if !$item;

    my $score = $item->ac || 0; # already includes enchantment

    $score++ if $item->mc >= 2;

    # this really should just check whether is_cursed is known to be zero
    $score-- if !defined($item->buc);

    # cursed bad!!
    $score -= 2 if $item->is_cursed;

    # XXX: damage, resistances, weight?

    $score++ if $item->includes_possibility('boots of speed')
             || $item->includes_possibility('gauntlets of power')
             || $item->includes_possibility('cloak of magic resistance')
             || $item->includes_possibility('helm of brilliance');

    return $score;
}

sub prepare {
    my $self = shift;

    return if $self->prepare_armor;
}

sub prepare_armor {
    my $self = shift;

    for my $slot (TAEB->equipment->armor_slots) {
        my $incumbent       = TAEB->equipment->$slot;
        my $incumbent_score = $self->_rate_armor($incumbent);

        # Can't remove it :(
        next if $incumbent && $incumbent->is_cursed;

        my @candidates = TAEB->inventory->find(
            type    => 'armor',
            subtype => $slot,
        );

        my ($best_score, $best_armor) = (0, undef);
        for my $candidate (@candidates) {
            my $rating = $self->_rate_armor($candidate);

            ($best_score, $best_armor) = ($rating, $candidate)
                if $rating > $best_score;
        }

        next if $best_score <= $incumbent_score;

        # XXX: This should be implemented with an exception/objection/veto
        next if !defined($best_armor->buc)
             && TAEB->current_tile->type eq 'altar';

        if ($incumbent) {
            $self->do(remove => item => $incumbent);
            $self->currently("Removing $incumbent to wear $best_armor.");
        }
        else {
            $self->do(wear => item => $best_armor);
            $self->currently("Putting on $best_armor.");
        }

        $self->urgency('normal');

        return $best_armor;
    }

    return 0;
}

sub pickup {
    my $self = shift;
    my $item = shift;

    return 0 unless $item->type eq 'armor';

    my $slot = $item->subtype;
    my $incumbent = TAEB->equipment->$slot;

    return $self->_rate_armor($item) > $self->_rate_armor($incumbent);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

