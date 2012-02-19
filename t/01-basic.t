use Test::More tests => 47;

package MyVal;

use Validation::Class;

load {
    plugins => ['FormFields']
};

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
    
package main ;

use FindBin;

no warnings 'redefine';

sub ok($;$) {
    Test::More::ok($_[1], $_[0]);
}

sub has($;$) {
    my ($html, $string) = @_;
    return $html =~ /$string/m;
}

my $tmps  = $FindBin::Bin . "/../share/templates";
my $input = MyVal->new(param => {});

my $form  = $input->form_fields;
   $form->{field_templates_location} = $tmps;

my $html  = '';
   
   $html = $form->render_field('login', 'text');
   diag 'processing the login field';
   
ok 'form rendered html for login', $html;
ok 'login rendered label', has $html, '<label for="login">';
ok 'login did not render an error', ! has $html, '<span class="errors">';
ok 'login rendered input:text', has $html, 'type="text"';

   $input->validate('login');
   $html = $form->render_field('login', 'text');
   diag 'validated the login field';

ok 'form rendered html for login', $html;
ok 'login rendered label', has $html, '<label for="login">';
ok 'login rendered errors', has $html, '<span class="errors">';
ok 'login errors consistent', has $html, '<span class="errors">Login invalid.';
ok 'login rendered input:text', has $html, 'type="text"';

   $html = $form->render_field('password', 'text');
   diag 'processing the password field';
   
ok 'form rendered html for password', $html;
ok 'password rendered label', has $html, '<label for="password">';
ok 'password did not render an error', ! has $html, '<span class="errors">';
ok 'password rendered input:text', has $html, 'type="text"';

   $input->validate('password');
   $html = $form->render_field('password', 'text');
   diag 'validated the password field';

ok 'form rendered html for password', $html;
ok 'password rendered label', has $html, '<label for="password">';
ok 'password rendered errors', has $html, '<span class="errors">';
ok 'password errors consistent', has $html, '<span class="errors">Password invalid.';
ok 'password rendered input:text', has $html, 'type="text"';

   $input->validate('login', 'password');
   $html = join "\n",
        $form->render_field('login', 'text'),
        $form->render_field('password', 'text')
   ;
   diag 'processing the login and password';
   
ok 'form rendered html for login', $html;
ok 'login rendered label', has $html, '<label for="login">';
ok 'login rendered errors', has $html, '<span class="errors">';
ok 'login errors consistent', has $html, '<span class="errors">Login invalid.';
ok 'login rendered input:text', has $html, 'type="text"';
ok 'form rendered html for password', $html;
ok 'password rendered label', has $html, '<label for="password">';
ok 'password rendered errors', has $html, '<span class="errors">';
ok 'password errors consistent', has $html, '<span class="errors">Password invalid.';
ok 'password rendered input:text', has $html, 'type="text"';

   $input->params->{login} = 'admin';
   $input->validate('login', 'password');
   $html = join "\n",
        $form->render_field('login', 'text'),
        $form->render_field('password', 'text')
   ;
   diag 'processing the login and password with login set';
   
ok 'form rendered html for login', $html;
ok 'login rendered label', has $html, '<label for="login">';
ok 'login did not render errors', has $html, '<span class="errors">';
ok 'login rendered input:text', has $html, 'type="text"';
ok 'form rendered html for password', $html;
ok 'password rendered label', has $html, '<label for="password">';
ok 'password rendered errors', has $html, '<span class="errors">';
ok 'password errors consistent', has $html, '<span class="errors">Password invalid.';
ok 'password rendered input:text', has $html, 'type="text"';

   $input->params->{login} = 'wrong';
   $input->validate('login', 'password');
   $html = join "\n",
        $form->render_field('login', 'text'),
        $form->render_field('password', 'text')
   ;
   diag 'processing the login and password with login set to fail';
   
ok 'form rendered html for login', $html;
ok 'login rendered label', has $html, '<label for="login">';
ok 'login rendered errors', has $html, '<span class="errors">';
ok 'login errors consistent', has $html, '<span class="errors">Login invalid.';
ok 'login rendered input:text', has $html, 'type="text"';
ok 'form rendered html for password', $html;
ok 'password rendered label', has $html, '<label for="password">';
ok 'password rendered errors', has $html, '<span class="errors">';
ok 'password errors consistent', has $html, '<span class="errors">Password invalid.';
ok 'password rendered input:text', has $html, 'type="text"';
