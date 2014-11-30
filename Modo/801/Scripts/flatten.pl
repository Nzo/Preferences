#perl
#AUTHOR: Seneca Menard
#version 1.7
#This script flattens the selected geometry by it's averaged normal.
#The script now remembers what your workplane was
#(7-23-06 bugfix) : doh.  the script wasn't working at all.   Now it works.  heh.
#(11-9-07 bugfix) : fixed a bug if symmetry was on, but there wasn't a selection on both sides
#(11-13-07 bugfix) : script now works properly if your UP axis is not Y.

my $mainlayer = lxq("query layerservice layers ? main");
my $constrain = lxq("tool.set const.bg ?");

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SAFETY CHECKS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Remember what the workplane was
my @WPmem;
@WPmem[0] = lxq("workPlane.edit cenX:? ");
@WPmem[1] = lxq("workPlane.edit cenY:? ");
@WPmem[2] = lxq("workPlane.edit cenZ:? ");
@WPmem[3] = lxq("workPlane.edit rotX:? ");
@WPmem[4] = lxq("workPlane.edit rotY:? ");
@WPmem[5] = lxq("workPlane.edit rotZ:? ");


#symm
our $symmAxis = lxq("select.symmetryState ?");
#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3)				{	lx("select.symmetryState none");	}

#Turn Constrain off
if ($constrain != 0){	lx("tool.set const.bg 0"); 	}

#reset and backup up axis in preferences
my $prefUpAxis = lxq("pref.value units.upAxis ?");
if ($prefUpAxis != 1){lx("pref.value units.upAxis 1");}


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO2 FIX))
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#sets the ACTR preset
our $seltype;
our $selAxis;
our $selCenter;
our $actr = 1;
if( lxq( "tool.set actr.select ?") eq "on")				{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.local ?") eq "on")				{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")				{	$seltype = "actr.pivot";			}
elsif( lxq( "tool.set actr.auto ?") eq "on")				{	$seltype = "actr.auto";			}
else
{
	$actr = 0;
	lxout("custom Action Center");
	if( lxq( "tool.set axis.select ?") eq "on")			{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")			{	 $selAxis = "view";			}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")			{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")			{	 $selAxis = "pivot";			}
	elsif( lxq( "tool.set axis.auto ?") eq "on")			{	 $selAxis = "auto";			}
	else										{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if( lxq( "tool.set center.select ?") eq "on")		{	 $selCenter = "select";		}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")		{	 $selCenter = "origin";		}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	elsif( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	else										{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
}
lx("tool.set actr.auto on");



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DETERMINE WHETHER TO RUN ON BOTH SYMM SIDES OR NOT.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#IF SYMMETRY IS ON : run the script on each side of symmetry.
if ($symmAxis != 3){
	lxout("symmetry is on");
	my @polys = lxq("query layerservice polys ? selected");
	my @negPolys;
	my @posPolys;
	foreach my $poly (@polys){
		my @pos = lxq("query layerservice poly.pos ? $poly");
		if (@pos[$symmAxis] > 0){
			push (@posPolys,$poly);
		}else{
			push (@negPolys,$poly);
		}
	}

	#NEG half
	if (@negPolys > 0){
		lx("select.drop polygon");
		foreach my $poly (@negPolys){	lx("select.element $mainlayer polygon add $poly");	}
		&flatten;
	}

	#POS half
	if (@posPolys > 0){
		lx("select.drop polygon");
		foreach my $poly (@posPolys){	lx("select.element $mainlayer polygon add $poly");	}
		&flatten;
	}

	#put ORIG SEL back
	lx("select.drop polygon");
	foreach my $poly (@polys){	lx("select.element $mainlayer polygon add $poly");	}

}
#IF 	SYMMETRY IS OFF : run the script once.
else{
	#run on all polys
	lxout("symmetry is off");
	&flatten;
}




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CLEANUP
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Put constrain back on if it was on beforehand
if ($constrain != 0)	{	lx("tool.set const.bg $constrain");	}

#Put your workplane back
lx("workPlane.edit [@WPmem[0]] [@WPmem[1]] [@WPmem[2]] [@WPmem[3]] [@WPmem[4]] [@WPmem[5]]");

#Set Symmetry back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";	}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#reset and backup up axis in preferences
if ($prefUpAxis != 1){lx("pref.value units.upAxis $prefUpAxis");}












#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------SUBROUTINES--------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

sub flatten{
	#flattens the selection
	lx("workPlane.fitSelect");
	lx("tool.set xfrm.stretch on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenY 0");
	lx("tool.setAttr center.auto cenY 0");
	lx("tool.setAttr center.auto cenY 0");
	lx("tool.setAttr axis.auto axisX [0.0 %]");
	lx("tool.setAttr axis.auto axisY [0.0 %]");
	lx("tool.setAttr axis.auto axisZ [100.0 %]");
	lx("tool.setAttr axis.auto axis [2]");
	lx("tool.setAttr axis.auto upX [100.0 %]");
	lx("tool.setAttr axis.auto upY [0.0 %]");
	lx("tool.setAttr axis.auto upZ [0.0 %]");
	lx("tool.setAttr xfrm.stretch factX [100.0 %]");
	lx("tool.setAttr xfrm.stretch factY [0.0 %]");
	lx("tool.setAttr xfrm.stretch factZ [100.0 %]");
	lx("tool.doApply");
	lx("tool.set xfrm.stretch off");
	lx("workPlane.reset");
}