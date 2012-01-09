package Gtk2::Ex::HyperTextView;

# ABSTRACT: Gtk2::TextView with links!

use warnings;
use strict;

use Gtk2;
use Gtk2::Pango;

# debugging...
use Smart::Comments '###';

use Glib::Object::Subclass
	Gtk2::TextView::,
	signals => {
		link_clicked => { param_types => [qw/Glib::String/] },
		'link_enter' => { param_types => [qw/Glib::String/] },
		'link_leave' => {                                   },
	},
	properties => [ ],
;

sub _parser { 'Gtk2::Ex::HyperTextView::Parser' }

sub INIT_INSTANCE {
	my $self = shift;

	$self->set_editable(0);
	$self->set_wrap_mode('word');
	$self->{parser} = $self->_parser->new(buffer => $self->get_buffer);

	$self->get_buffer->create_tag(
		'bold',
		weight		=> PANGO_WEIGHT_BOLD
	);
	$self->get_buffer->create_tag(
		'italic',
		style		=> 'italic',
	);
	$self->get_buffer->create_tag(
		'word_wrap',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'head1',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 15 * PANGO_SCALE,
		wrap_mode	=> 'word',
		foreground	=> '#404080',
        'pixels-above-lines' => 10,
	);
	$self->get_buffer->create_tag(
		'head2',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 12 * PANGO_SCALE,
		wrap_mode	=> 'word',
		foreground	=> '#404080',
	);
	$self->get_buffer->create_tag(
		'head3',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 9 * PANGO_SCALE,
		wrap_mode	=> 'word',
		foreground	=> '#404080',
	);
	$self->get_buffer->create_tag(
		'head4',
		weight		=> PANGO_WEIGHT_BOLD,
		size		=> 6 * PANGO_SCALE,
		wrap_mode	=> 'word',
		foreground	=> '#404080',
	);
	$self->get_buffer->create_tag(
		'monospace',
		family		=> 'monospace',
		wrap_mode	=> 'none',
		foreground	=> '#606060',
	);
	$self->get_buffer->create_tag(
		'typewriter',
		family		=> 'monospace',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'link',
		foreground	=> 'blue',
		underline	=> 'single',
		wrap_mode	=> 'word',
	);
	$self->get_buffer->create_tag(
		'indented',
		left_margin	=> 40,
	);
	$self->get_buffer->create_tag(
		'normal',
		wrap_mode	=> 'word',
	);

	# put a 6pixel white border around the text:
	$self->set_border_window_size('left', 6);
	$self->set_border_window_size('top', 6);
	$self->set_border_window_size('right', 6);
	$self->set_border_window_size('bottom', 6);
	$self->modify_bg('normal', Gtk2::Gdk::Color->new(65535, 65535, 65535));

	my $cursor	= Gtk2::Gdk::Cursor->new('xterm');
	my $url_cursor	= Gtk2::Gdk::Cursor->new('hand2');

	$self->signal_connect('button_release_event', sub { $self->clicked($_[1]) ; return 0 });

	$self->signal_connect_after('realize' => sub {
		my $view = shift;

		$view->get_window('text')->set_events([qw(exposure-mask
							  pointer-motion-mask
							  button-press-mask
							  button-release-mask
							  key-press-mask
							  structure-mask
							  property-change-mask
							  scroll-mask)]);

		return 0;
	});

	$self->signal_connect('motion_notify_event' => sub {
		my ($view, $event) = @_;
		my ($x, $y) = $view->window_to_buffer_coords('text', $event->x, $event->y);
		my $over_link = $view->get_iter_at_location($x, $y)->has_tag($view->get_buffer()->get_tag_table()->lookup("link"));

		if ($over_link && !$self->{was_over_link}) {
			# user has just brought the mouse over a link:
			$self->{was_over_link} = 1;
			my $text = $self->get_link_text_at_iter($view->get_iter_at_location($x, $y));

			$self->signal_emit('link_enter', $text) if ($text ne '');

		} elsif (!$over_link && $self->{was_over_link}) {
			# user has just moved the mouse away from a link:
			$self->{was_over_link} = 0;

			$self->signal_emit('link_leave');

		}

		$view->get_window('text')->set_cursor($over_link ? $url_cursor : $cursor);
		return 0;
	});
}

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::Ex::HyperTextView;

	my $viewer = Gtk2::Ex::HyperTextView->new;

    # ... load some content ...

	$viewer->show;				# see, it's a widget!

	my $window = Gtk2::Window->new;
	$window->add($viewer);

	$window->show;

	Gtk2->main;

=head1 DESCRIPTION

Gtk2::Ex::HyperTextView is a widget for rendering documents containing
hyperlinks. It is based on the L<Gtk2::TextView> widget and provides a widget
that can be used by itself, or subclassed (e.g.
L<Gtk2::Ex::HyperTextView::Pod>.

Gtk2::Ex::HyperTextView widgets inherit all the methods and properties of
L<Gtk2::TextView> widgets. Full information about text buffers can be found
in the Gtk+ documentation at
L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>.

=head1 OBJECT HIERARCHY

    L<Glib::Object>
    +--- L<Gtk2::Object>
         +--- L<Gtk2::Widget>
              +--- L<Gtk2::Editable>
                   +--- L<Gtk2::TextView>
                        +--- L<Gtk2::Ex::HyperTextView>

=head1 CONSTRUCTOR

	my $view = Gtk2::Ex::HyperTextView->new;

creates and returns a new Gtk2::Ex::HyperTextView widget.


=head1 ADDITIONAL METHODS

	$viewer->clear;

This clears the viewer's buffer and resets the iter. You should never need to use this method since the loader methods (see L<Document Loaders> below) will do it for you.

=cut

sub _init_db {
    my $self = shift;
    ### _init_db()...
    #$self->{db} = Pod::Simple::Search->new->survey;
}

=pod

	my $db = $viewer->get_db;

This method returns a hashref that contains the POD document database used internally by Gtk2::Ex::HyperTextView. If you want to improve startup performance, you can cache this database using a module like C<Storable>. To load a cached database into a viewer object, call

	$viewer->set_db($db);

before making a call to any of the document loader methods below (otherwise, Gtk2::Ex::HyperTextView will create a new database for itself). If you want to tell Gtk2::Ex::HyperTextView to create a new document database (for example, after a new module has been installed), use

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

	$name = 'SYNOPSIS';

	$view->jump_to($name);

this scrolls the HyperTextView window to the selected mark.

=cut

sub jump_to {
	my ($self, $name) = @_;
	my $mark = $self->get_mark($name);
	return undef unless (ref($mark) eq 'Gtk2::TextMark');
	return $self->scroll_to_mark($mark, undef, 1, 0, 0);
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

The C<load()> method is a wrapper to a number of specialised document loaders. You can call one of these loaders directly to override the order in which Gtk2::Ex::HyperTextView searches for documents:

	$viewer->load_doc($perldoc);

loads a perldoc file or Perl module documentation, or undef on failure.

	$viewer->load_file($file);

loads POD from a file, or returns undef on failure.

	$viewer->load_string($string);

This method renders the POD data in the C<$string> variable.

=cut

# XXX
sub load_doc {
	my ($self, $doc) = @_;
	return ($self->{db}->{$doc} ? $self->load_file($self->{db}->{$doc}) : undef);
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

    ### in load_string(): ref $self->parser

	$self->clear;
    ### one...
	$self->parser->clear_marks;
    ### two...
	$self->parser->parse_from_string($string);
    ### three...
	return 1;
}

=pod

	$parser = $view->parser;

returns the C<Gtk2::Ex::HyperTextView::Parser> object used to render the POD data.

=cut

sub parser {
	return $_[0]->{parser};
}

sub clicked {
	my ($self, $event) = @_;
	my ($x, $y) = $self->window_to_buffer_coords('widget', $event->get_coords);
	my $iter = $self->get_iter_at_location($x, $y);
	my $text = $self->get_link_text_at_iter($iter);
	if (defined($text) && $text ne '') {
		$self->signal_emit('link_clicked', $text);
	}
	return 1;
}

sub get_link_text_at_iter {
	my ($self, $iter) = @_;
	my $tag = $self->get_buffer->get_tag_table->lookup('link');
	if ($iter->has_tag($tag)) {
		my $offset = $iter->get_offset;
		for (my $i = 0 ; $i < scalar(@{$self->parser->{links}}) ; $i++) {
			my ($text,  $this_offset) = @{@{$self->parser->{links}}[$i]};
			if ($offset >= $this_offset && $offset <= ($this_offset + length($text))) {
				return $text;
			}
		}
	}
	return undef;
}

!!42;

__END__

=pod

=head1 SIGNALS

Gtk2::Ex::HyperTextView inherits all of Gtk2::TextView's signals, and has the following:

=head2 The C<'link_clicked'> signal

	$viewer->signal_connect('link_clicked', \&clicked);

	sub clicked {
		my ($viewer, $link_text) = @_;
		print "user clicked on '$link_text'\n";
	}

Emitted when the user clicks on a hyperlink within the POD. This may be a section title, a document name, or a URL. The receiving function will be giving two arguments: a reference to the Gtk2::Ex::HyperTextView object, and a scalar containing the link text.

=head2 The C<'link_enter'> signal

	$viewer->signal_connect('link_enter', \&enter);

	sub enter {
		my ($viewer, $link_text) = @_;
		print "user moused over '$link_text'\n";
	}

Emitted when the user moves the mouse pointer over a hyperlink within the POD. This may be a section title, a document name, or a URL. The receiving function will be giving two arguments: a reference to the Gtk2::Ex::HyperTextView object, and a scalar containing the link text.

=head2 The C<'link_leave'> signal

	$viewer->signal_connect('link_leave', \&leave);

	sub clicked {
		my $viewer = shift;
		print "user moused out\n";
	}

Emitted when the user moves the mouse pointer out from a hyperlink within the POD. 

=head1 Getting and Setting Font preferences

You can set the font used to render text in a Gtk2::Ex::HyperTextView widget like so:

	$viewer->modify_font(Gtk2::Pango::FontDescription->from_string($FONT_NAME);

To modify the appearance of the various elements of the page, you need to extract the L<Gtk2::TextTag> from the viewer's buffer:

	my $tag = $viewer->get_buffer->get_tag_table->lookup('monospace');
	$tag->set('font' => $FONT_NAME);

The tags used by Gtk2::Ex::HyperTextView are:

=over

=item C<bold>

Used to format bold text.

=item C<italic>

Used to format italic text.

=item C<head1> ... C<head4>

Used to format headers.

=item C<monospace>

Used to format preformatted text.

=item C<typewriter>

Used to format inline preformatted text.

=item C<link>

Used to format hyperlinks.

=back

=head1 BUGS AND TASKS

Gtk2::Ex::HyperTextView is a work in progress. All comments, complaints, offers of help and patches are welcomed.

We currently know about these issues:

=over

=item *

When rendering long documents the UI freezes for too long.

=item *

Some strangeness with Unicode.

=back

=head1 PREREQUISITES

=over

=item *

L<Gtk2> (obviously). The most recent version will be from L<http://gtk2-perl.sf.net/>.

=item *

L<Pod::Parser>

=item *

L<IO::Scalar>

=item *

L<Pod::Simple::Search>

=back

L<Gtk2::Ex::HyperTextView::Parser>, which is part of the L<Gtk2::Ex::HyperTextView> distribution, also requires L<Locale::gettext>.

=head1 SEE ALSO

=over

=item *

L<Gtk2> or L<http://gtk2-perl.sf.net/>

=item *

L<http://developer.gnome.org/doc/API/2.0/gtk/GtkTextView.html>

=item *

L<Gtk2::Ex::HyperTextView::Parser>,
L<Gtk2::Ex::PodViewer>, L<Gtk2::Ex::HyperTextView::Pod>,
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
documentation contained in the L<Gtk2::Ex::PodViewer> distribution.
PodViewer's authors are listed as Gavin Brown, Torsten Schoenfeld and Scott
Arrington.

All errors, and the work realigning the code, have been done by Chris Weyl.

=head1 COPYRIGHT

Copyright (c) 2012 Chris Weyl. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

Large chunks of code in this package are:

(c) 2003-2005 Gavin Brown (gavin.brown@uk.com). All rights reserved. This
program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
