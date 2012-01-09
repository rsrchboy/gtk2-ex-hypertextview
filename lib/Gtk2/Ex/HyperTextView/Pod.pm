package Gtk2::Ex::HyperTextView::Pod;

# ABSTRACT: Pod-aware Gtk2::TextView

use warnings;
use strict;

use parent 'Gtk2::Ex::HyperTextView';

use Gtk2::Ex::HyperTextView::Pod::Parser;
use Pod::Simple::Search;

# debugging...
use Smart::Comments '###';

use Glib::Object::Subclass
    Gtk2::Ex::HyperTextView::,
    #__PACKAGE__,
    signals    => { },
    properties => [ ],
    ;

sub _parser { 'Gtk2::Ex::HyperTextView::Pod::Parser' }

=head1 SYNOPSIS

    use Gtk2 -init;
    use Gtk2::Ex::HyperTextView::Pod;

    my $viewer = Gtk2::Ex::HyperTextView::Pod->new;

    $viewer->load('/path/to/file.pod');    # load a file
    $viewer->load('IO::Scalar');        # load a module
    $viewer->load('perlvar');        # load a perldoc
    $viewer->load('bless');            # load a function

    $viewer->show;                # see, it's a widget!

    my $window = Gtk2::Window->new;
    $window->add($viewer);

    $window->show;

    Gtk2->main;

=head1 DESCRIPTION

Gtk2::Ex::HyperTextView::Pod is a widget for rendering Perl POD documents. It is based on the Gtk2::TextView widget and uses Pod::Parser for manipulating POD data.

Gtk2::Ex::HyperTextView::Pod widgets inherit all the methods and properties of Gtk2::TextView widgets. Full information about text buffers can be found in the Gtk+ documentation at L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>.

=head1 OBJECT HIERARCHY

    L<Glib::Object>
    +--- L<Gtk2::Object>
         +--- L<Gtk2::Widget>
              +--- L<Gtk2::Editable>
                   +--- L<Gtk2::TextView>
                        +--- L<Gtk2::Ex::HyperTextView>
                            +--- L<Gtk2::Ex::HyperTextView::Pod>

=head1 METHODS

    $viewer->clear;

This clears the viewer's buffer and resets the iter. You should never need to use this method since the loader methods (see L<Document Loaders> below) will do it for you.

=cut

sub _init_db {
    my $self = shift;
    ### _init_db()...
    $self->{db} = Pod::Simple::Search->new->survey;
}

=pod

    my $db = $viewer->get_db;

This method returns a hashref that contains the POD document database used internally by Gtk2::Ex::HyperTextView::Pod. If you want to improve startup performance, you can cache this database using a module like C<Storable>. To load a cached database into a viewer object, call

    $viewer->set_db($db);

before making a call to any of the document loader methods below (otherwise, Gtk2::Ex::HyperTextView::Pod will create a new database for itself). If you want to tell Gtk2::Ex::HyperTextView::Pod to create a new document database (for example, after a new module has been installed), use

    $viewer->reinitialize_db;

=cut

sub set_db { $_[0]->{db} = $_[1] }

sub get_db { $_[0]->{db} }

sub reinitialize_db { shift()->_init_db }

sub clear {
    my $self = shift;
    $self->get_buffer->set_text('');
    $self->{parser}{iter} = $self->get_buffer->get_iter_at_offset(0);
    return 1;
}

=pod

    @marks = $view->get_marks;

This returns an array of section headers. So for example, a POD document of the form

    =pod

    =head1 NAME

    =head1 SYNOPSIS

    =cut

would result in

    @marks = ('NAME', 'SYNOPSIS');

You can then use the contents of this array to create a document index.

=cut

sub get_marks {
    return $_[0]->{parser}->get_marks;
}

=pod

    $name = 'SYNOPSIS';

    $mark = $view->get_mark($name);

returns the GtkTextMark object referred to by C<$name>.

=cut

sub get_mark {
    return $_[0]->{parser}->get_mark($_[1]);
}

=pod

    $viewer->load($document);

Loads a given document. C<$document> can be a perldoc name (eg., C<'perlvar'>), a module (eg. C<'IO::Scalar'>), a filename or the name of a Perl builtin function from L<perlfunc>. Documents are searched for in that order, that is, the L<perlvar> document will be loaded before a file called C<perlvar> in the current directory.

=cut

sub load {
    my ($self, $name) = @_;

    $self->_init_db if (!defined($self->{db}));

    return 1 if $self->load_function($name);
    return 1 if $self->load_doc($name);
    return 1 if $self->load_file($name);

    return undef;
}

=pod

=head1 DOCUMENT LOADERS

The C<load()> method is a wrapper to a number of specialised document loaders. You can call one of these loaders directly to override the order in which Gtk2::Ex::HyperTextView::Pod searches for documents:

    $viewer->load_doc($perldoc);

loads a perldoc file or Perl module documentation, or undef on failure.

    $viewer->load_file($file);

loads POD from a file, or returns undef on failure.

    $viewer->load_function($function);

This method scans the L<perlfunc> POD document for the documentation for a given function. The algorithm for this is lifted from the L<Pod::Perldoc> module, so it should work identically to C<perldoc -f [function]>.

    $viewer->load_string($string);

This method renders the POD data in the C<$string> variable.

=head2 DEPRECATED DOCUMENT LOADERS

The following document loads are now deprecated, and are now just wrapper of the C<load_doc> method:

    $viewer->load_perldoc($perldoc);
    $viewer->load_module($module);

=cut

sub load_perldoc { $_[0]->load_doc($_[1]) }
sub load_module { $_[0]->load_doc($_[1]) }

sub load_doc {
    my ($self, $doc) = @_;
    return ($self->{db}->{$doc} ? $self->load_file($self->{db}->{$doc}) : undef);
}

sub load_function {
    my ($self, $function) = @_;
    my $perlfunc = $self->perlfunc;
    return undef if ($perlfunc eq '');
    open(PERLFUNC, $perlfunc) or return undef;
    # ignore everything up to here:
    while (<PERLFUNC>) {
        last if /^=head2 Alphabetical Listing of Perl Functions/;
    }
    # this is lifted straight from Pod/Perldoc.pm, with only a couple
    # of modifications:
    my $found = 0;
    my $inlist = 0;
    my $pod = '';
    while (<PERLFUNC>) {
        if (/^=item\s+\Q$function\E\b/)  {
            $found = 1;
        }
        elsif (/^=item/) {
            last if $found > 1 and not $inlist;
        }
        next unless $found;
        if (/^=over/) {
            ++$inlist;
        }
        elsif (/^=back/) {
            --$inlist;
        }
        $pod .= $_;
        ++$found if /^\w/;
    }
    close(PERLFUNC) or return undef;
    return undef if ($pod eq '');
    $self->load_string($pod);
    return 1;
}

sub load_file {
    my ($self, $file) = @_;
    if (-e $file) {
        $self->clear;
        $self->parser->clear_marks;
        $self->parser->parse_from_file($file);
        return 1;
    } else {
        return undef;
    }
}

sub load_string {
    my ($self, $string) = @_;
    $self->clear;
    $self->parser->clear_marks;
    $self->parser->parse_from_string($string);
    return 1;
}

sub perlfunc {
    my $self = shift;
    return $self->{perlfunc} if (defined($self->{perlfunc}));
    foreach my $dir (@INC) {
        my $file = sprintf('%s/pod/perlfunc.pod', $dir);
        if (-e $file) {
            $self->{perlfunc} = $file;
            return $self->{perlfunc};
        }
    }
}

!!42;

__END__

=head1 THE podviewer PROGRAM

C<podviewer> is installed with Gtk2::Ex::HyperTextView::Pod. It is a simple
Pod viewing program. It is pretty minimal, but does do the job quite well.
Those looking for a more feature-complete documentation browser should try
PodBrowser, available from L<http://jodrell.net/projects/podbrowser>.

=head1 SEE ALSO

=over

=item *

L<Gtk2> or L<http://gtk2-perl.sf.net/>

=item *

L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>

=item *

L<Gtk2::Ex::PodViewer>, L<Gtk2::Ex::HyperTextView::Pod::Parser>,
L<Gtk2::Ex::HyperTextView::Markdown>.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.

Bugs, feature requests and pull requests through GitHub are most welcome; our
page and repo (same URI):

    https://github.com/RsrchBoy/gtk2-ex-hypertextview

=head1 RATIONALE

This work is a "restatement" of the L<Gtk2::Ex::PodViewer> package.  It's been
altered such that the link-aware subclass of L<Gtk2::TextView> is contained in
its own base class (L<Gtk2::Ex::HyperTextView>_, such that Pod (and other)
viewers can in turn descend from the base class.

=head1 AUTHORS

This package is largely a restatement/realignment of the code and
documentation contained in the L<Gtk2::Ex::Pod::Viewer> distribution.
PodViewer's authors are Gavin Brown, Torsten Schoenfeld and Scott Arrington.

All errors, and the work realigning the code, have been done by Chris Weyl.

=head1 COPYRIGHT

Copyright (c) 2012 Chris Weyl. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

Large chunks of code in this package are:

(c) 2003-2005 Gavin Brown (gavin.brown@uk.com). All rights reserved. This
program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. 

=cut
