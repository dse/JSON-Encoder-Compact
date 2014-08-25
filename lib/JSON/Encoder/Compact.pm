package JSON::Encoder::Compact;
use warnings;
use strict;

use JSON qw(-convert_blessed_universally);

sub new {
    my ($class, %args) = @_;
    my $self = bless({ json => JSON->new()->allow_nonref()->pretty()->convert_blessed(),
		       compactness => 1,
		       %args }, $class);
    return $self;
}

sub encode {
    my ($self, $data) = @_;
    if (ref($data)) {
	$data = $self->{json}->encode($data);
	$data = $self->{json}->decode($data);
    }
    my $encoded = "";
    $self->__encode(stringref => \$encoded, data => $data);
    return $encoded . "\n";
}

sub __encode {
    my ($self, %args) = @_;

    my $stringref     = $args{stringref};
    my $data          = $args{data};
    my $indent        = $args{indent}        // 0;
    my $extra_compact = $args{extra_compact} // 0;
    my $stack         = $args{stack}         // [];

    my $ref = ref($data);
    if (!$ref) {
	my $enc = $self->{json}->encode($data);
	chomp($enc);
	$$stringref .= $enc;
    } elsif ($ref eq "ARRAY") {
	if (scalar(@$data) == 0) {
	    $$stringref .= "[]";
	} else {
	    my $newlines = 1;
	    if ($extra_compact) {
		$newlines = 0;
	    } elsif ($self->{compactness} >= 2) {
		if (!grep { ref($_) } @$data) {
		    $newlines = 0;
		}
	    }
	    $$stringref .= "[ ";
	    $indent += 2;

	    my $extra_compact = $extra_compact || eval { $self->{extra_compact}->{$stack->[-1] . "[]"} };

	    for (my $i = 0; $i <= scalar(@$data); $i += 1) {
		if ($i) {
		    if ($newlines) {
			$$stringref .= ",\n" . (" " x $indent);
		    } else {
			$$stringref .= ", ";
		    }
		}
		$self->__encode(stringref => $stringref,
				data => $data->[$i],
				indent => $indent,
				extra_compact => $extra_compact,
				stack => [@$stack, "[]"]);
	    }
	    $$stringref .= " ]";
	}
    } elsif ($ref eq "HASH") {
	my @keys = keys(%$data);
	if (scalar(@keys) == 0) {
	    $$stringref .= "{}";
	} else {
	    my $newlines = 1;
	    if ($extra_compact) {
		$newlines = 0;
	    } elsif ($self->{compactness} >= 2) {
		if (!grep { ref($_) } values(%$data)) {
		    $newlines = 0;
		}
	    }
	    $$stringref .= "{ ";
	    $indent += 2;
	    for (my $i = 0; $i < scalar(@keys); $i += 1) {
		my $key = $keys[$i];
		my $extra_compact = $extra_compact || eval { $self->{extra_compact}->{$key} };
		my $value = $data->{$key};
		my $sub = eval { $self->{convert_key}->{$key} };
		if ($sub && ref($sub) eq "CODE") {
		    my $new_value = $sub->($value);
		    next if !defined $new_value;
		    $value = $new_value;
		}
		if ($i) {
		    if ($newlines) {
			$$stringref .= ",\n" . (" " x $indent);
		    } else {
			$$stringref .= ", ";
		    }
		}
		my $key_enc = $self->{json}->encode($key);
		chomp($key_enc);
		$$stringref .= $key_enc;
		$$stringref .= ": ";
		$self->__encode(stringref => $stringref,
				data => $value,
				indent => $indent + length($key_enc) + 2,
				extra_compact => $extra_compact,
				stack => [@$stack, $key]);
	    }
	    $$stringref .= " }";
	}
    } else {
	my $enc = $self->{json}->encode("$data");
	chomp($enc);
	$$stringref .= $enc;
    }
}

1; # End of JSON::Encoder::Compact
