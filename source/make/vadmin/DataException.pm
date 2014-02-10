package DataException;

  use base qw(Error);
  use overload ('""' => 'stringify');

  sub new
  {
    my $self = shift;
    my $text = "" . shift;
    my @args = ();

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;  # Enables storing of stacktrace

    $self->SUPER::new(-text => $text, @args);
  }
  1;
	  
  
  package ConnectionInitializationFailure;
  use base qw(DataException);
  1;
  
  package ConnectionFailure;
  use base qw(DataException);
  1;


 package SqlFailure;
  use base qw(DataException);
  1;