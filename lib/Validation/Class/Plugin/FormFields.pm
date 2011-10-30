# ABSTRACT: Validation::Class HTML Form Field Renderer

use strict;
use warnings;

package Validation::Class::Plugin::FormFields;
{
  $Validation::Class::Plugin::FormFields::VERSION = '0.0.1';
}

use Moose::Role;
use File::Copy;
use File::ShareDir qw/dist_dir/;
use Template;
use Template::Stash;

our $VERSION = '0.0.1'; # VERSION


# field element templates
has field_templates => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {{
        dir          => shift->field_templates_location,
        text         => 'text_field.tt',
        password     => 'password_field.tt',
        select       => 'select_field.tt',
        multi_select => 'select_multiple_field.tt',
        textarea     => 'textarea_field.tt',
        radio        => 'radio_field.tt',
        check        => 'check_field.tt',
        hidden       => 'hidden_field.tt',
        file         => 'file_field.tt'
    }}
);

# field element templates location
has field_templates_location => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $dir     = '';
        
        my $package = __PACKAGE__;
           $package =~ s/::/\-/g;
           
        eval { $dir = dist_dir($package) };
        return join "/", $dir, "templates";
    }
);

# retreive the template for a type
sub field_template {
    my ($self, $type) = @_;
    return join "/",
        $self->field_templates->{dir},
        $self->field_templates->{$type},
}

# hook into the validation classes initilization
sub new {
    my ($class, $self) = @_;
    
    # add element ddirective

    #$self->directives->{element} = {
    #    mixin => 1, # allowed in mixins
    #    field => 1, # allowed in fields
    #    multi => 0  # never an array
    #};
    
}

# render form element template based on the field definition
sub render_field {
    my ($self, $field, $type, $args) = @_;
    my $content   = '';
    my $variables = {
        class => $self,
        field => $self->fields->{$field},
        vars  => $args
    };
    my $template  = Template->new(
        INTERPOLATE => 1,
        EVAL_PERL   => 1,
        ABSOLUTE    => 1,
        ANYCASE     => 1
    );
    $template->process($self->field_template($type), $variables, \$content);
    $content =~ s/(\w)\n{2,}/$1\n/mgi;               # poor-mans tidy attempt
    $content =~ s/(\w)\s{2,}/$1\n/mgi;               # poor-mans tidy attempt
    $content =~ s/\n\s{2,}\n/\n/mg;                  # poor-mans tidy attempt
    $content =~ s/(\w)\n([^\t])/$1 \n\n    $2/mg;    # poor-mans tidy attempt
    return "$content\n";
}

# define custom template virtual methods
$Template::Stash::LIST_OPS->{ in_array } = sub {
    my $list  = shift;
    my $query = shift;
       $list = "ARRAY" eq ref $list ? $list : [$list];
    return (grep { $_ eq $query } @$list) ? 1 : 0;
};

1;
__END__
=pod

=head1 NAME

Validation::Class::Plugin::FormFields - Validation::Class HTML Form Field Renderer

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    package MyApp::Validation;
    
    use Validation::Class; __PACKAGE__
        ->load_plugins('FormFields');
    
    # a validation rule
    field 'login'  => {
        label      => 'User Login',
        error      => 'Login invalid.',
        required   => 1,
        validation => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'admin' ? 1 : 0;
        }
    };
    
    # a validation rule
    field 'password'  => {
        label         => 'User Password',
        error         => 'Password invalid.',
        required      => 1,
        validation    => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'pass' ? 1 : 0;
        }
    };
    
    # elsewhere is the application
    package main ;
    
    my $form = MyApp::Validation->new(params => $params);
    
    $form->validate('login', 'password');
    
    print $form->render_field('login', 'text');
    print $form->render_field('password', 'password');

=head1 DESCRIPTION

More importanly than explaining what this plugin is, I will first proclaim what
it IS NOT. Validation::Class::Plugin::FormFields is not a HTML form and/or
HTML element construction kit, nor is it a one-size-fits-all form handling machine,
it is however a plugin for use with your L<Validation::Class> class that allows
you to render HTML form fields based on your defined validation fields in
their given states.

For more information about defining fields (validation rules), feel free to look
over L<Validation::Class>. 

=head1 DISCLAIMER

B<EXPERIMENTAL>, Validation::Class::Plugin::FormFields is super new and is
currently only a proof-of-concept. Though the current API is not expected to
change much, I can't make any promises.

=head1 ATTRIBUTES

=head2 field_templates

The field_templates attribute holds a hashref of field template filenames and
their shortnames.

=head2 field_templates_location

The field_templates_location attribute is the absolute location to the folder
where the field templates are stored.

=head1 METHODS

=head2 field_template

The field_template method returns the complete path and filename of the
specified template.

    my $form = MyApp::Validation->new(params => $params);
    my $template = $form->field_template('radio');

=head2 render_field

The render_field method renders an HTML block based on the specified arguments
passed to it. This method takes three arguments, the name of the field, type of
element to render, and an optional hashref to further configure the rendering
process.

The render_field method render an HTML control block and not just a single
HTML element. The HTML control block will always be a div element which wraps
the HTML form input fields.

    package MyApp::Validation;
    
    use Validation::Class; __PACKAGE__
        ->load_plugins('FormFields');
    
    field 'login'  => {
        label      => 'User Login',
        error      => 'Login invalid.',
        required   => 1,
        validation => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'admin' ? 1 : 0;
        }
    };
    
    field 'password'  => {
        label         => 'User Password',
        error         => 'Password invalid.',
        required      => 1,
        validation    => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'pass' ? 1 : 0;
        }
    };
    
    field 'remember'  => {
        label         => 'Remember Authentication',
        error         => 'Remember authentication invalid.',
        options       => 'Yes, No'
    };
    
    # elsewhere is the application
    package main ;
    
    my $form = MyApp::Validation->new(params => $params);
    
    my $user_field  = $form->render_field('login', 'text');
    my $pass_field  = $form->render_field('password', 'password');
    
    my $remember_me = $form->render_field('remember', 'check', {
        select  => 'Yes',
        options => [
            { text => 'Yes', value => 'Yes' },
            { text => 'No', value => 'No' },
        ]
    });

The following is a list of HTML elements that the render_field method can
produce along with their syntax and options.

=head3 check

The check option instructs the render_field method to produce a checkbox or
checkbox group depending on whether you supply an arrayref of options.

    # renders a single checkbox 
    my $checkbox = $form->render_field($field, 'check');

    # renders a checkbox group
    my $checkbox = $form->render_field($field, 'check', {
        select  => [@default_value],
        options => [
            { text => '...', value => '...' },
            { text => '...', value => '...' },
        ]
    });

=head3 file

The file option instructs the render_field method to produce a file upload
form field.

    # renders a single file element
    my $upload = $form->render_field($field, 'file');

=head3 hidden

The hidden option instructs the render_field method to produce a hidden form
field.

    # renders a single hidden element
    my $hidden = $form->render_field($field, 'hidden');

=head3 password

The password option instructs the render_field method to produce a
password-protected input form field.

    # renders a single password element
    my $password = $form->render_field($field, 'password');

=head3 radio

The radio option instructs the render_field method to produce a radio button or
radio button group depending on whether you supply an arrayref of options.

    # renders a single radio button
    my $radio = $form->render_field($field, 'radio');

    # renders a radio button group
    my $radio = $form->render_field($field, 'radio', {
        select  => $default_value,
        options => [
            { text => '...', value => '...' },
            { text => '...', value => '...' },
        ]
    });

=head3 select

The select option instructs the render_field method to produce a selectbox also
known as a dropdown box.

    # renders a single selectbox
    my $selectbox = $form->render_field($field, 'selectbox');

=head3 multi_select

The multi_select option instructs the render_field method to produce a selectbox
configured to allow the selection of multiple values.

    # renders a multi selectbox or combobox
    my $combobox = $form->render_field($field, 'multi_select', {
        select  => [@default_values],
        options => [
            { text => '...', value => '...' },
            { text => '...', value => '...' },
        ]
    });

=head3 text

The text option instructs the render_field method to produce a standard
text input form field.

    # renders a single textbox
    my $text = $form->render_field($field, 'text');

=head3 textarea

The textarea option instructs the render_field method to produce a textarea for
multi-line text input.

    # renders a single textarea
    my $textarea = $form->render_field($field, 'textarea');

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

