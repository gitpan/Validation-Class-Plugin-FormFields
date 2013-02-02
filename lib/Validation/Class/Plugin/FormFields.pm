# ABSTRACT: HTML Form Field Renderer for Validation::Class

package Validation::Class::Plugin::FormFields;

use strict;
use warnings;
use overload '""' => \&render, fallback => 1;

use Carp;

use List::MoreUtils 'any';
use Validation::Class::Util;
use HTML::Element;

our $VERSION = '7.900021'; # VERSION


sub new {

    my $class     = shift;
    my $prototype = shift;

    my $self = {
        target    => '',
        elements  => {},
        prototype => $prototype
    };

    return bless $self, $class;

}


sub checkbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('checkbox', $name, %attributes);

    return $self;

}


sub checkgroup {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('checkgroup', $name, %attributes);

    return $self;

}


sub error_count {

    my $self = shift;

    return $self->prototype->error_count(@_);

}


sub error_fields {

    my $self = shift;

    return $self->prototype->error_fields(@_);

}


sub errors {

    my $self = shift;

    return $self->prototype->errors(@_);

}


sub errors_to_string {

    my $self = shift;

    return $self->prototype->errors_to_string(@_);

}

sub declare {

    my ($self, $method, $name, %attributes) = @_;

    my $proto = $self->{prototype};

    croak qq(Can't declare new element without a field and type),
        unless $name && $method
    ;

    croak qq(Can't locate field $name for use with element $method),
        unless $proto->fields->has($name)
    ;

    my $field = $proto->fields->get($name);

    $attributes{id}   ||= $field->name;
    $attributes{name} ||= $field->name;

    my $value;

    if (defined $attributes{value}) {
        $value = $attributes{value};
    }

    else {
        $value = $field->default;
    }

    my $param = []; # everything gets easier if we always expect an arrayref

    if ($proto->params->has($name)) {
        $param = $proto->params->get($name);
        $param = isa_arrayref($param) ? $param : [$param];
    }

    my $processor = "_declare_$method";

    $self->$processor($field, $param, $value, %attributes)
        if $self->can($processor)
    ;

    return $self;

}

sub _declare_checkbox {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    my $proto = $self->proto;

    $attributes{type} ||= 'checkbox';

    $value = isa_arrayref($value) ? $value->[0] : $value;

    croak qq(Can't process checkbox without a default value for field $name)
        unless $value
    ;

    # set value attribute
    $attributes{value} = $value;

    # set checked attribute
    if (any { $_ eq $value } @{$param}) {
        $attributes{checked} = 'checked';
    }

    # set attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_checkgroup {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my @elements = ();

    my $proto = $self->proto;

    $attributes{type} ||= 'checkbox';

    $value = isa_arrayref($value) ? $value->[0] : $value;

    # set value attribute (although it'll likely be overwritten)
    $attributes{value} = $value;

    my @opts = grep defined, @{$field->options};

    croak qq(Can't process checkbox group without options for field $name),
        unless @opts
    ;

    my %values = map { $_ => $_ } @{$param};

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }

        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }

        else {
            ($v, $c) = ($opt, $opt);
        }

        my $element = HTML::Element->new('input');

        # set basic attributes
        while (my($key, $val) = each(%attributes)) {
            $element->attr($key, $val);
        }

        $element->attr(value => $v);
        $element->push_content(HTML::Element->new('span', _content => [$c]));
        $element->attr(checked => 'checked') if $v eq $values{$v};

        push @elements, $element;

    }

    return $self->{elements}->{$name} = \@elements;

}

sub _declare_hidden {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    my $proto = $self->proto;

    $attributes{type} ||= 'hidden';

    $value = isa_arrayref($value) ? $value->[0] : $value;

    croak qq(Can't process hidden field without a default value for field $name)
        unless $value
    ;

    # set value attribute
    $attributes{value} = $value;

    # set attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_selectbox {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('select');

    # default state (minor liberties taken)
    if (defined $attributes{placeholder}) {
        $element->push_content(
            HTML::Element->new('option',
                value => '', _content => [
                    delete $attributes{placeholder}
                ]
            )
        );
    }

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    my $proto = $self->proto;

    $value = isa_arrayref($value) ? $value->[0] : $value;

    my @opts = grep defined, @{$field->options};

    croak qq(Can't process selectbox without options for field $name),
        unless @opts
    ;

    my %values = map { $_ => $_ } @{$param};

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }

        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }

        else {
            ($v, $c) = ($opt, $opt);
        }

        my $option = HTML::Element->new('option');

        $option->attr(value => $v);
        $option->push_content($c);
        $option->attr(selected => 'selected') if $v eq $values{$v};

        $element->push_content($option);

    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_radiobutton {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    my $proto = $self->proto;

    $attributes{type} ||= 'radio';

    $value = isa_arrayref($value) ? $value->[0] : $value;

    croak qq(Can't process radiobutton without a default value for field $name)
        unless $value
    ;

    # set value attribute
    $attributes{value} = $value;

    # set checked attribute
    if (any { $_ eq $value } @{$param}) {
        $attributes{checked} = 'checked';
    }

    # set attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_radiogroup {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my @elements = ();

    my $proto = $self->proto;

    $attributes{type} ||= 'radio';

    $value = isa_arrayref($value) ? $value->[0] : $value;

    # set value attribute (although it'll likely be overwritten)
    $attributes{value} = $value;

    my @opts = grep defined, @{$field->options};

    croak qq(Can't process radio group without options for field $name),
        unless @opts
    ;

    my %values = map { $_ => $_ } @{$param};

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }

        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }

        else {
            ($v, $c) = ($opt, $opt);
        }

        my $element = HTML::Element->new('input');

        # set basic attributes
        while (my($key, $val) = each(%attributes)) {
            $element->attr($key, $val);
        }

        $element->attr(value => $v);
        $element->push_content(HTML::Element->new('span', _content => [$c]));
        $element->attr(checked => 'checked') if $v eq $values{$v};

        push @elements, $element;

    }

    return $self->{elements}->{$name} = \@elements;

}

sub _declare_textarea {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('textarea');

    my $proto = $self->proto;

    $attributes{type} ||= 'text';

    $value = $param->[0] || (isa_arrayref($value) ? $value->[0] : $value);

    $element->push_content($value);

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_textbox {

    my ($self, $field, $param, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    my $proto = $self->proto;

    $attributes{type} ||= 'text';

    $value = $param->[0] || (isa_arrayref($value) ? $value->[0] : $value);

    # set value attribute
    $attributes{value} = $value;

    # set attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}


sub element {

    my ($self, $target) = @_;

    $target ||= $self->{target};

    return $self->{elements}->{$target};

}


sub hidden {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('hidden', $name, %attributes);

    return $self;

}


sub lockbox {

    goto &password;

}


sub multiselect {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{multiple} = 'yes';

    $self->selectbox($name, %attributes);

    return $self;

}


sub password {

    my ($self, $name, %attributes) = @_;

    $attributes{type} = 'password';

    $self->textbox($name, %attributes);

    return $self;

}

sub proto {

    goto &prototype;

}


sub prototype {

    my ($self) = @_;

    return $self->{prototype};

}


sub radiobutton {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('radiobutton', $name, %attributes);

    return $self;

}


sub radiogroup {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('radiogroup', $name, %attributes);

    return $self;

}


sub selectbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('selectbox', $name, %attributes);

    return $self;

}


sub textarea {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('textarea', $name, %attributes);

    return $self;

}


sub textbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('textbox', $name, %attributes);

    return $self;

}


sub render {

    my ($self, $target)  = @_;

    my $element = $self->element($target);

    return isa_arrayref($element) ?
        [map { $_->as_HTML } @{$element}] : $element->as_HTML
    ;

}

sub render_inner {

    my ($self)  = @_;

    my @pairs;
    my %attrs = $self->element->all_attr;

    my $type = delete $attrs{_tag};

    for (keys %attrs) {
        delete $attrs{$_} if /^_/;
    }

    my @attrs = %attrs;

    push @pairs, sprintf('%s="%s"', splice(@attrs, 0, 2)) while @attrs;

    return $type . ' ' . join ' ', @pairs;

}

1;

__END__
=pod

=head1 NAME

Validation::Class::Plugin::FormFields - HTML Form Field Renderer for Validation::Class

=head1 VERSION

version 7.900021

=head1 SYNOPSIS

    # this plugin is in working condition but untested!!!

    use Validation::Class::Simple;
    use Validation::Class::Plugin::FormFields;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => { required => 1 },
            password => { required => 1 },
            remember => { options  => 'remember' },
            notify   => { options  => 'notify' }
        }
    );

    my $fields = $rules->plugin('form_fields');

    printf "%s\n", $fields->textbox('username', placeholder => 'Username');
    printf "%s\n", $fields->lockbox('password', placeholder => 'Password');

=head1 DESCRIPTION

Validation::Class::Plugin::FormFields is a plugin for L<Validation::Class>
which can leverage your validation class field definitions to render HTML form
elements. Please note that this plugin is intentionally lacking in
sophistication and try to take as few liberties as possible.

=head1 RATIONALE

Validation::Class::Plugin::FormFields is not an HTML form handler, nor is it an
HTML form builder, renderer, construction kit, or framework. Why render fields
individually and not the entire form? Form handling is a heavily opinionated
subject and this plugin reflects the following perspective.

HTML form generation, done literally, has too many contraints and considerations
to ever be truly ideal. Consider the following, it's been tried many many times
before, it's never pretty, too many conflicting contexts (css, js, security and
identification), css wants the form configured a certain way for styling
purposes, js wants the form configured a certain way for introspection purposes,
the app wants the form configured a certain way for processing purposes, etc.

So why do we continue to try? HTML forms are like werewolves and developers love
silver bullets, but bullets are actually made out of lead, not silver. So how do
you kill werewolves with lead? Hint, not by shooting them obviously. I'd argue
that we never really wanted complete form rendering anyway, what we actually
wanted was a simple way to reduce the tedium and repetitiveness that comes with
creating HTML form elements and handling submission and validation of the
associated data. We keep getting it wrong because we keep trying to build on
top of the same misconceptions.

So maybe we should backup a bit and try something different. The generating of
HTML elements is much less constrained and definately much more straight-forward.

=head1 METHODS

=head2 checkbox

The checkbox method initializes an HTML::Element checkbox object to represent a
checkbox in an HTML form. The value and checked attributes will be automatically
included based on the state of the validation class prototype; determined based
on the existence of the following: a parameter value, a field value, or field
default value. Note that if multiple values exist, only the first value will be
used.

    $self->checkbox('field_name', %attributes_list);

=head2 checkgroup

The checkgroup method initializes an array of HTML::Element checkbox objects to
represent a list of checkboxes in an HTML form. The value and checked attributes
will be automatically included based on the state of the validation class
prototype; determined based on the existence of the following: a parameter value,
a field value, or field default value. Please note that rendering is based-on
the options directive and each checkbox is appended with a span element
containing the option's key or value for each individual option. Please see the
L<"options directive"|Validation::Class::Directive::Options> for additional
information. The rendered elements will always be returned as an array.

    field_name => {
        options => [
            'Choice 1',
            'Choice 2',
            'Choice 3',
        ]
    }

    # or

    field_name => {
        options => [
            '1|Choice 1',
            '2|Choice 2',
            '3|Choice 3',
        ]
    }

    # then

    $self->checkgroup('field_name', %attributes_list);

=head2 error_count

    $self->error_count;

See L<Validation::Class::Prototype/error_count> for full documentation.

=head2 error_fields

    $self->error_fields;

See L<Validation::Class::Prototype/error_fields> for full documentation.

=head2 errors

    $self->errors;

See L<Validation::Class::Prototype/errors> for full documentation.

=head2 errors_to_string

    $self->errors_to_string;

See L<Validation::Class::Prototype/errors_to_string> for full documentation.

=head2 element

The element method returns the pre-configured HTML::Element object(s) for the
given field, or the last field operated on if no argument is passed.

    $self->element('field_name');

=head2 hidden

The hidden method initializes an HTML::Element hidden-field object to represent
a hidden field in an HTML form. The value attribute will be automatically
included based on the state of the validation class prototype; determined based
on the existence of the following: a parameter value, a field value, or field
default value. Note that if multiple values exist, only the first value will be
used.

    $self->hidden('field_name', %attributes_list);

=head2 lockbox

The lockbox method is an alias for the password method which initializes an
HTML::Element password-field object to represent a password in an HTML form.
The value attribute will be automatically included based on the state of the
validation class prototype; determined based on the existence of the following:
a parameter value, a field value, or field default value. Note that if multiple
values exist, only the first value will be used.

    $self->lockbox('field_name', %attributes_list);

=head2 multiselect

The multiselect method initializes an HTML::Element selectbox object to
represent a selectbox with a list of options where multiple options may be
selected in an HTML form. The value and selected attributes will be automatically
included based on the state of the validation class prototype; determined based
on the existence of the following: a parameter value, a field value, or field
default value. Please note that rendering is based-on the options directive and
each option element's contents contains the option's key or value for each
individual option. Please see the L<"options directive"|Validation::Class::Directive::Options>
for additional information.

    field_name => {
        options => [
            'Choice 1',
            'Choice 2',
            'Choice 3',
        ]
    }

    # or

    field_name => {
        options => [
            '1|Choice 1',
            '2|Choice 2',
            '3|Choice 3',
        ]
    }

    # then

    $self->multiselect('field_name', %attributes_list);

=head2 password

The password method initializes an HTML::Element password-field object to
represent a password in an HTML form. The value attribute will be automatically
included based on the state of the validation class prototype; determined based
on the existence of the following: a parameter value, a field value, or field
default value. Note that if multiple values exist, only the first value will be
used.

    $self->password('field_name', %attributes_list);

=head2 prototype

The prototype (or proto) method returns the underlying
L<Validation::Class::Prototype> object.

    $self->prototype;

=head2 radiobutton

The radiobutton method initializes an HTML::Element radiobutton object to
represent a radio-button in an HTML form. The value and checked attributes will
be automatically included based on the state of the validation class prototype;
determined based on the existence of the following: a parameter value, a field
value, or field default value. Note that if multiple values exist, only the
first value will be used.

    $self->radiobutton('field_name', %attributes_list);

=head2 radiogroup

The radiogroup method initializes an array of HTML::Element radiobutton objects
to represent a list of radiobuttons in an HTML form. The value and checked
attributes will be automatically included based on the state of the validation
class prototype; determined based on the existence of the following: a parameter
value, a field value, or field default value. Please note that rendering is
based-on the options directive and each radiobutton is appended with a span
element containing the option's key or value for each individual option. Please
see the L<"options directive"|Validation::Class::Directive::Options> for
additional information. The rendered elements will always be returned as an
array.

    field_name => {
        options => [
            'Choice 1',
            'Choice 2',
            'Choice 3',
        ]
    }

    # or

    field_name => {
        options => [
            '1|Choice 1',
            '2|Choice 2',
            '3|Choice 3',
        ]
    }

    # then

    $self->radiogroup('field_name', %attributes_list);

=head2 selectbox

The selectbox method initializes an HTML::Element selectbox object to represent
a selectbox with a list of options in an HTML form. The value and selected
attributes will be automatically included based on the state of the validation
class prototype; determined based on the existence of the following: a parameter
value, a field value, or field default value. Please note that rendering is
based-on the options directive and each option element's contents contains the
option's key or value for each individual option. Please see the
L<"options directive"|Validation::Class::Directive::Options> for additional
information.

    field_name => {
        options => [
            'Choice 1',
            'Choice 2',
            'Choice 3',
        ]
    }

    # or

    field_name => {
        options => [
            '1|Choice 1',
            '2|Choice 2',
            '3|Choice 3',
        ]
    }

    # then

    $self->selectbox('field_name', %attributes_list);

    # or, in keeping with convention, ...
    # to include a default state, i.e. an initial option with an blank value

    $self->selectbox('field_name', placeholder => 'Choose One');

=head2 textarea

The textarea method initializes an HTML::Element textarea-field object to
represent a textarea in an HTML form. The element's contents will be
automatically included based on the state of the validation class prototype;
determined based on the existence of the following: a parameter value, a field
value, or field default value. Note that if multiple values exist, only the
first value will be used.

    $self->textarea('field_name', %attributes_list);

=head2 textbox

The textbox method initializes an HTML::Element textbox object to represent a
textbox in an HTML form. The value attribute will be automatically included
based on the state of the validation class prototype; determined based on the
existence of the following: a parameter value, a field value, or field default
value. Note that if multiple values exist, only the first value will be used.

    $self->textbox('field_name', %attributes_list);

=head2 render

The render method renders-and-returns pre-configured HTML::Element object(s)
for the given field, or the last field operated on if no argument is passed.
This method is called automatically when the object is used in scalar context.

    $self->render('field_name');

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

