#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetFilter.pl,v 1.1 1996/11/21 20:13:52 jcmurphy Exp $
#
# NAME
#   GetFilter.pl
#
# USAGE
#   GetFilter.pl [username] [password] [filtername]
#
# DESCRIPTION
#   Retrieve and print information about the named filter.
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@acsu.buffalo.edu
#
# $Log: GetFilter.pl,v $
# Revision 1.1  1996/11/21 20:13:52  jcmurphy
# Initial revision
#
#

use ARS;

# SUBROUTINE
#   printl
#
# DESCRIPTION
#   prints the string after printing X number of tabs

sub printl {
    my $t = shift;
    my @s = @_;

    if(defined($t)) {
	for( ; $t > 0 ; $t--) {
	    print "\t";
	}
	print @s;
    }
}

($username, $password, $filtername) = @ARGV;
if(!defined($filtername)) {
    print "Usage: $0 [username] [password] [filtername]\n";
    exit 0;
}

$AR_OPERATION_GET = 1;
$AR_OPERATION_SET = 2;
$AR_OPERATION_CREATE = 4;
$AR_OPERATION_DELETE = 8;
$AR_OPERATION_MERGE = 16;

%ars_opSet = (
	      $AR_OPERATION_GET, "Display", 
	      $AR_OPERATION_SET, "Modify", 
	      $AR_OPERATION_CREATE, "Create", 
	      $AR_OPERATION_DELETE, "Delete", 
	      $AR_OPERATION_MERGE, "Merge"
	      );

$ctrl = ars_Login("", $username, $password);
($finfo = ars_GetFilter($ctrl, $filtername)) ||
    die "error in GetFilter: $ars_errstr";

print "** Filter Info:\n";
print "Name        : \"".$finfo->{"name"}."\"\n";
print "Order       : ".$finfo->{"order"}."\n";
print "Schema      : \"".$finfo->{"schema"}."\"\n";
print "opSet       : ".Decode_opSetMask($finfo->{"opSet"})."\n";
print "Enable      : ".$finfo->{"enable"}."\n";
print "Query       : ".$finfo->{"query"}."\n";
print "actionList  : \n";

ProcessActions(@{$finfo->{actionList}});

print "helpText    : \"".$finfo->{"helpText"}."\"\n";
print "timestamp   : ".localtime($finfo->{"timestamp"})."\n";
print "owner       : ".$finfo->{"owner"}."\n";
print "lastChanged : ".$finfo->{"lastChanged"}."\n";
print "changeDiary : ".$finfo->{"changeDiary"}."\n";

ars_Logoff($ctrl) || die "error while logging out: $ars_errstr";

exit 0;

# Most of these subroutines were taken directly from Show_ALink.pl

# SUBROUTINE
#   PrintArith
#
# DESCRIPTION
#   Attempt to "pretty print" the arith expression (just for
#   the hell of it)
#
# NOTES
#   Notic that parenthesis are printed, although they are not
#   explicitly part of the node information. They are derived
#   from the ordering of the tree, instead. If you want to actually
#   *evaluate* the expression, you will have to derive the 
#   parenthetical encoding from the tree ordering.
#
#   Here is an example equation and how it is encoded:
#
#   ((10 + 2) / 3)
#
#          "/"
#         /   \
#       "+"    3
#      /  \
#    10    2
#
#   ARS apparently sorts the operations for you (based on their
#   mathematical precedence) so you should evaluate the tree from 
#   the bottom up. 
#
#   ars_web.cgi has an evaluation routine for computing the value
#   of a arith structure. we will probably break it out into a
#   perl module.
#
# THOUGHTS
#   I don't know if this routine will work for all cases.. but
#   i did some tests and it looked good. Ah.. i just wrote it
#   for the fun of it.. so who cares? :)

sub PrintArith {
    my $a = shift;

    PrintArith_Recurs($a, 0);
    print "\n";
}

sub PrintArith_Recurs {
    my $a = shift;
    my $p = shift;
    my $n, $i;

    if(defined($a)) {
	$n = $a->{left};
	if(defined($n)) {
	    if(defined($n->{arith})) {
		PrintArith_Recurs($n->{arith}, $p+1);
	    } else {
		for($i=1;$i<$p;$i++) {
		    print " ( ";
		}
	    }
	    print " ( $n->{value} " if defined($n->{value});
	    print " ( \$$n->{field}->{fieldId}\$ " if defined($n->{field});
	    print " ( $n->{function} " if defined($n->{function});
	}
	print " $a->{oper} ";
	$n = $a->{right};
	if(defined($n)) {
	    print " $n->{value} ) " if defined($n->{value});
	    print " \$$n->{field}->{fieldId}\$ ) " if defined($n->{field});
	    PrintArith_Recurs($n->{arith}) if defined($n->{arith});
	    print " $n->{function} ) " if defined($n->{function});
	}
    }
}


# SUBROUTINE
#   ProcessArithStruct
#
# DESCRIPTION
#   This routine breaks down the arithmetic structure

sub ProcessArithStruct {
    my $a = shift;
    my $n;

    if(defined($a)) {
	printl 5, "Operation: $a->{oper}\n";
	$n = $a->{left};
	if(defined($n)) {
#	    printl 5, "(Left) ";
	    printl 5, "Value: \"$n->{value}\"\n" if defined($n->{value});
	    printl 5, "Field: \$$n->{field}->{fieldId}\$\n" if defined($n->{field});
	    printl 5, "Process: $n->{process}\n" if defined($n->{process});
	    ProcessArithStruct($n->{arith}) if defined($n->{arith});
	    printl 5, "Function: $n->{function}\n" if defined($n->{function});
	    printl 5, "DDE: DDE not supported in ARSperl\n" if defined($n->{dde});
	}
	$n = $a->{right};
	if(defined($n)) {
#	    printl 5, "(Right) ";
	    printl 5, "Value: \"$n->{value}\"\n" if defined($n->{value});
	    printl 5, "Field: \$$n->{field}->{fieldId}\$\n" if defined($n->{field});
	    printl 5, "Process: $n->{process}\n" if defined($n->{process});
	    ProcessArithStruct($n->{arith}) if defined($n->{arith});
	    printl 5, "Function: $n->{function}\n" if defined($n->{function});
	    printl 5, "DDE: DDE not supported in ARSperl\n" if defined($n->{dde});
	}
    }
}

# SUBROUTINE
#   ProcessFunctionList
#
# DESCRIPTION
#   Parse and dump the function list structure. 

sub ProcessFunctionList {
    my $t = shift;   # how much indentation to use
    my @func = @_;
    my $i;

    printl $t, "Function Name: \"$func[0]\" .. Num of args: $#func\n";

    # we need to process all of the arguments listed.

    for($i=1;$i<=$#func;$i++) {
	printl $t+1, "Value: \"$func[$i]->{value}\"\n" if defined($func[$i]->{value});
	printl $t+1, "Field: \$$func[$i]->{field}->{fieldId}\$\n" if defined($func[$i]->{field});
	printl $t+1, "Process: $func[$i]->{process}\n" if defined($func[$i]->{process});

	PrintArith($func[$i]->{arith}) if defined($func[$i]->{arith});

	# if the arg is a pointer to another function, we need to process
	# it recursively.

	if(defined($func[$i]->{function})) {
	    ProcessFunctionList($t+1, @{$func[$i]->{function}});
	}
	printl $t+1, "DDE: DDE not supported in ARSperl\n" if defined($func[$i]->{dde});
    }
}

# SUBROUTINE
#   ProcessSetFields
#
# DESCRIPTION
#   This routine dumps the various forms of the Set Fields
#   action in active links.
 
sub ProcessSetFields {
    my $field = shift;
 
    if(defined($field->{none})) {
        printl 3, "No set fields instructions found.\n";
    }
    if(defined($field->{value})) {
        printl 3, "Value: \$$field->{value}\$\n";
    }
    if(defined($field->{field})) {
        printl 3, "Field: $field->{field}\n";
    }
    if(defined($field->{process})) {
        printl 3, "Process: $field->{process}\n";
    }
    if(defined($field->{arith})) {
        printl 3, "Arithmetic:\n";
#       ProcessArithStruct($field->{arith});
        printl 4, "Expression: ";
        PrintArith($field->{arith});
    }
    if(defined($field->{function})) {
        printl 3, "Function:\n";
        ProcessFunctionList(4, @{$field->{function}});
    }
    if(defined($field->{dde})) {
        printl 3, "DDE not implemented in ARSperl.\n";
    }
}

# SUBROUTINE
#   ProcessActions
#
# DESCRIPTION
#   this routine processes the list of actions for this filter,
#   deciding what actions are defined and dumping the appropriate 
#   information.
# 
# AUTHOR
#   jeff murphy

sub ProcessActions {
    my @actions = @_;
    if(defined(@actions)) {
        $act_num = 1;
        foreach $action (@actions) {
            printl 1, "Action $act_num:\n";
            if(defined($action->{assign_fields})) {
                printl 2, "Set Fields:\n";
                foreach $setFields (@{$action->{assign_fields}}) {
                    printl 3, "fieldId: $setFields->{fieldId}\n";
                    ProcessSetFields($setFields->{assignment});
                }
            }
            if(defined($action->{message})) {
                
                # message text is formatted as:
                #
                # Type X Num XXXXX Text [XXXXXX...]
 
                $action->{message} =~ 
                    /Type\ ([0-9]+)\ Num\ ([0-9]+)\ Text \[(.*)\]/;
                printl 2, "Message:\n";
                printl 3, "Type: $MessageTypes[$1] ($1)\n";
                printl 3, "Num: $2\n";
                printl 3, "Text: $3\n";
            }
            if(defined($action->{process})) {
                printl 2, "Process: ".$action->{process}."\n";
            }
            if(defined($action->{notify})) {
                printl 2, "Notify:\n";
		printl 3, "user: $action->{notify}{user}\n";
		printl 3, "notifyMechanism: ".
		    ("Notifier", "E-Mail", "User Default", "Cross Ref",
		     "Other")[$action->{notify}{notifyMechanism}-1]."\n";
		printl 3, "notifyMechanismXRef: $action->{notify}{notifyMechanismXRef}\n";
		printl 3, "subjectText: $action->{notify}{subjectText}\n";
		printl 3, "notifyText: $action->{notify}{notifyText}\n";
		printl 3, "fieldIdListType: ".
		    ("None", "List", "Changed", "All")
			[$action->{notify}{fieldIdListType}-1]."\n";
		printl 3, "Field List: $action->{notify}{fieldList}\n";
		foreach $fid (@{$action->{notify}{fieldList}}) {
		    printl 4, "$fid\n";
		}
            }
            if(defined($action->{none})) {
                printl 2, "No actions specified.\n";
            }
            $act_num++;
        }
        print "\n";
    } else {
        print "No actions to process!\n";
    }
}

# SUBROUTINE
#   Decode_opSetMask (value)
#
# DESCRIPTION
#   Takes the numeric opSet field and returns a list (space separated)
#   of operation names that this filter will execute on.
# 
# AUTHOR
#   jeff murphy

sub Decode_opSetMask {
    my $m = shift;
    my $s, $v;
 
    if(defined($m)) {
        foreach $v (sort keys %ars_opSet) {
            if($v & $m) {
                $s = $s.$ars_opSet{$v}." ";
            }
        }
    }
    return($s);
}
