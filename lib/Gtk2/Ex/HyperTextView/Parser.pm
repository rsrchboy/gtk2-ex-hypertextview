package Gtk2::Ex::HyperTextView::Parser;

# ABSTRACT: Parser base class

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts 0.006;
use MooseX::Types::Path::Class ':all';

use Path::Class;

# debugging...
use Smart::Comments;

#has iter => (is => 'rwp', ...);
#has links => (is => 'rwp', ...);

has current_file => (
    is        => 'rwp',
    isa       => File,
    predicate => 1,
    clearer   => 1,
    coerce    => 1,
);

has current_source => (
    is        => 'rwp',
    isa       => 'Str',
    predicate => 1,
    clearer   => 1,
);

# XXX
has buffer => (is => 'ro', isa => 'Object', required => 1);

sub _build_iter { shift->buffer->get_iter_at_offset(0) }

# XXX
has marks => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef[ArrayRef]',
    clearer => 1,

    handles => {

        push_mark => 'push',
        #get_marks => [ map => sub { ... } ],
    },
);

sub parse_from_file {
    my ($self, $fn) = @_;

    #my $file = file $fn;
    #my $contents = $file->slurp;
    #my $contents = $file->slurp;
    #$self->parse_from_string($contents);

    $self->parse_from_string(file($fn)->slurp);
    $self->_set_current_file($fn);
    return 1;
}


sub parse_from_string {

    warn;
}

!!42;

__END__

-- att

iter
links

-- method

get_marks
get_mark
clear_marks
parse_from_string
parse_from_file


