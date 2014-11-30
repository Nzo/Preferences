#perl
#Perfect Circle
#AUTHOR: Seneca Menard
#version 1.6 (modo2)

#This script is for taking a POLY(s) or EDGELOOP(s) and moving the vertices so they form a perfect circle.
#This script was made because I often STENCIL or KNIFE a CIRCLE onto a mesh, and waste a lot of time tweaking the verts to try to get it perfectly round...
#-If you have MULTIPLE POLYGONS selected, it'll only pay attention to the BORDER VERTS.
#-If you have VERTS selected it will convert the selection to EDGES, so if converting the selection to edges didn't result in EDGELOOPS, then this script won't work
#-(7-18-05) bugfix: the script will work If you're using centimeters, millimeters, etc now.
#(2-2-06) MODO2 FIX and the script now works in symmetry!
#(7-3-07) fixed a small workplane restoration bug.

#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SAFETY CHECKS
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO2 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;
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
	#popup("AC ($selAxis <> $selCenter)");
}
#popup("seltype = $seltype");


#Remember what the workplane was and turn it off
my @backupWP;
@backupWP[0] = lxq ("workPlane.edit cenX:? ");
@backupWP[1] = lxq ("workPlane.edit cenY:? ");
@backupWP[2] = lxq ("workPlane.edit cenZ:? ");
@backupWP[3] = lxq ("workPlane.edit rotX:? ");
@backupWP[4] = lxq ("workPlane.edit rotY:? ");
@backupWP[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");

#this will make sure that you're working in METRIC UNITS and METERS (fixed for modo2)
our $unitSys = lxq("pref.value units.system ?");
our $prefUnit = lxq("pref.value units.default ?");
if ($unitSys ne "metric"){	#metric
	lxout("PREFERENCES : Unit System = $unitSys");
	lx("pref.value units.system metric");
}
if ($prefUnit ne "meters"){	#meters
	lxout("PREFERENCES : Default Unit = $prefUnit ");
	lx("pref.value units.default meters");
}

#IF in EDGE mode
if(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) && lxq( "select.count edge ?" ))
{
	our $sel_type= "edge";
}

#IF in POLY mode
elsif(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" ))
{
	lx("select.drop edge");
	lx("select.type polygon");
	lx("select.boundary");
	our $sel_type= "polygon";
}

#IF in VERTEX mode
elsif(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" ))
{
	lx("select.convert edge");
	our $sel_type= "vertex";
}

else
{
	die("You must have some polys or verts or edges selected");
}


#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SYMMETRY CODE
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#Turn off and protect Symmetry
my $symmAxis = lxq("select.symmetryState ?");
#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3)				{	lx("select.symmetryState none");	}

#our @edgeListPos;
#our @edgeListNeg;
our %vertPosTable;
#our %vertPosTablePos;
#our %vertPosTableNeg;

#create a table for all vert positions if symmetry is on.
if ($symmAxis != 3)
{
	#figure out what the NON symm axes are.
	our $nonSymmAxis1;
	our $nonSymmAxis2;
	if ($symmAxis == 0){$nonSymmAxis1 = 1; $nonSymmAxis2 = 2;}
	elsif ($symmAxis == 1){$nonSymmAxis1 = 0; $nonSymmAxis2 = 2;}
	elsif ($symmAxis == 2){$nonSymmAxis1 = 0; $nonSymmAxis2 = 1;}

	#throw the verts into the vertPosTable.
	my @edges  = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges)
	{
		my @verts = split (/[^0-9]/, $edge);
		my @vert1Pos = lxq("query layerservice vert.pos ? @verts[1]");
		my @vert2Pos = lxq("query layerservice vert.pos ? @verts[2]");

		$vertPosTable{@verts[1]} = \@vert1Pos;
		$vertPosTable{@verts[2]} = \@vert2Pos;
	}
}



#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SORT THE ROWS
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
our $mainlayer = lxq("query layerservice layers ? main");

#CREATE AND EDIT the edge list.  [remove ( )] (FIXED FOR M2.  I'm not using the multilayer query anymore)
our @origEdgeList = lxq("query layerservice edges ? selected");
s/\(// for @origEdgeList;
s/\)// for @origEdgeList;


our @origEdgeList_edit = @origEdgeList;
our @vertRow = split(/,/, @origEdgeList_edit[0]);
shift(@origEdgeList_edit);
our @vertRow;
our @vertRowList;
our @OrigWPmem;
our @WPmem;


while (($#origEdgeList_edit + 1) != 0)
{
	#this is a loop to go thru and sort the edge loops
	@vertRow = split(/,/, @origEdgeList_edit[0]);
	shift(@origEdgeList_edit);
	&sortRow;

	#take the new edgesort array and add it to the big list of edges.
	push(@vertRowList, "@vertRow");
}

#for ($i = 0; $i < ($#vertRowList + 1) ; $i++) {	lxout("- - -vertRow # ($i) = @vertRowList[$i]"); }




#--------------------------------------------
#FIND ALL EDGEROWS' ANGLE
#--------------------------------------------
lx("workPlane.fitSelect");
@OrigWPmem[0] = lxq ("workPlane.edit cenX:? ");
@OrigWPmem[1] = lxq ("workPlane.edit cenY:? ");
@OrigWPmem[2] = lxq ("workPlane.edit cenZ:? ");
@OrigWPmem[3] = lxq ("workPlane.edit rotX:? ");
@OrigWPmem[4] = lxq ("workPlane.edit rotY:? ");
@OrigWPmem[5] = lxq ("workPlane.edit rotZ:? ");
#lxout("origEdgeList = @origEdgeList");
#lxout("vertRow = @vertRow");
#lxout("vertRowList = @vertRowList");
#lxout("ORIG WORKPLANE = @OrigWPmem[0],@OrigWPmem[1],@OrigWPmem[2],@OrigWPmem[3],@OrigWPmem[4],@OrigWPmem[5]");



#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#BEGIN THE WORK for (EACH) vertrow
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
our %skipRow;
for ($j = 0; $j < ($#vertRowList + 1) ; $j++)
{
	#whether or not to skip a SYMM moved row
	#lxout("Running script on vertRow (@vertRowList[$j])");
	#lxout("skipRow{$j} = $skipRow{$j} ");
	if ($skipRow{$j} != 1)
	{

		#lxout("NEW VERTROW----------------------");
		#load up the (CURRENT) vertrow and remove any duplicate verts
		my @verts = split (/[^0-9]/, @vertRowList[$j]);
		if (@verts[0] == @verts[-1]) { pop(@verts); }



		#--------------------------------------------
		#SELECT THE (CURRENT) VERTROW
		#--------------------------------------------
		lx("select.drop vertex");
		foreach my $vert (@verts) { lx("select.element [$mainlayer] vertex add index:$vert"); }



		#--------------------------------------------
		#FIND THE (CURRENT) VERTROW's CENTER
		#--------------------------------------------
		lx("workPlane.fitSelect");
		#@WPmem[0] = lxq ("workPlane.edit cenX:? ");
		#@WPmem[1] = lxq ("workPlane.edit cenY:? ");
		#@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
		#if ($useAllRowsWorkplane == 1)	{	lx("workPlane.edit [@WPmem[0]] [@WPmem[1]] [@WPmem[2]] [@OrigWPmem[3]] [@OrigWPmem[4]] [@OrigWPmem[5]]");	}
		#lxout("workplane($j) = @WPmem[0],@WPmem[1],@WPmem[2]");



		#--------------------------------------------
		#FLATTEN THE (CURRENT) VERTROW
		#--------------------------------------------
		lx("tool.set actr.selectauto on");
		lx("tool.set xfrm.stretch on");
		lx("tool.setAttr center.select cenX [0 m]");
		lx("tool.setAttr center.select cenY [0 m]");
		lx("tool.setAttr center.select cenZ [0 m]");
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



		#--------------------------------------------
		#FIND THE (CURRENT) VERTROW's RADIUS
		#--------------------------------------------
		my $vert0 = @verts[0];
		my $vert1 = @verts[int($#verts * 0.5)];
		my $vert2 = @verts[int($#verts * 0.25)];
		my $vert3 = @verts[int($#verts * 0.75)];
		my $diameter1 = distance($vert0,$vert1);
		my $diameter2 = distance($vert2,$vert3);
		my $radiusAverage = ($diameter1 + $diameter2) * 0.25;



		#--------------------------------------------
		#CREATE THE (CURRENT) TEMP DISC THAT WILL BE USED FOR VERT PLACEMENTS
		#--------------------------------------------
		my $cylVerts = @verts;
		lx("tool.set prim.cylinder on");
		lx("tool.setAttr prim.cylinder sides [$cylVerts]");
		lx("tool.setAttr prim.cylinder cenX [0 m]");
		lx("tool.setAttr prim.cylinder cenY [0 m]");
		lx("tool.setAttr prim.cylinder cenZ [0 m]");
		lx("tool.setAttr prim.cylinder sizeX [$radiusAverage]");
		lx("tool.setAttr prim.cylinder sizeY [0 m]");
		lx("tool.setAttr prim.cylinder sizeZ [$radiusAverage]");
		lx("tool.setAttr prim.cylinder axis [1]");
		lx("tool.doApply");
		lx("tool.set prim.cylinder off");



		#--------------------------------------------
		#FIND the closest vert from the (CURRENT) vertrow to the last vert on the new disc
		#--------------------------------------------
		my $lastVert = lxq("query layerservice vert.index ? last");
		my @discArray;
		for (my $i = 0; $i < (@verts) ; $i++) { push(@discArray,($lastVert-$i));	}
		my $smallestFakeDist = ($radiusAverage*2);
		my $closestVert;
		my $closestVertArrayNum;
		my $vertArrayCount = 0;
		#lxout("discArray = @discArray");
		#lxout("lastVert = $lastVert");

		foreach my $vert (@verts)
		{
			my $fakeDist = fakeDistance($vert,$lastVert);
			if ($fakeDist < $smallestFakeDist)
			{
				$smallestFakeDist = $fakeDist;
				$closestVert = $vert;
				$closestVertArrayNum = $vertArrayCount;
			}
			$vertArrayCount++;
		}



		#--------------------------------------------
		#Now reorder that vertrow so that the closest vert is now array num 0
		#--------------------------------------------
		my $spliceAmount = (($#verts+1) - $closestVertArrayNum);
		#lxout("closestVertArrayNum = $closestVertArrayNum <><> spliceAmount = $spliceAmount ");
		#lxout("MY VERTS LIST BEF: @verts");
		my @vertsSplice = splice(@verts, $closestVertArrayNum,$spliceAmount);
		#lxout("MY VERTS LIST MID: @verts");
		splice(@verts, 0, 0, @vertsSplice);
		#lxout("MY VERTS LIST AFT: @verts");



		#--------------------------------------------
		#MAKE SURE the (CURRENT) vertrow is flowing in the same dir as the current disc
		#--------------------------------------------
		my $distCheck1 = fakeDistance(@discArray[1],@verts[1]);
		my $distCheck2 = fakeDistance(@discArray[1],@verts[-1]);

		#lxout("distCheck1 = $distCheck1 <><> distCheck2 = $distCheck2");
		if ($distCheck2 < $distCheck1)
		{
			@verts = reverse(@verts);
			pop(@verts);
			splice(@verts, 0, 0, $closestVert);
			#lxout("I'M REVERSING THE VERTROW!");
		}



		#--------------------------------------------
		#MOVE THE (CURRENT) VERTROW TO THE CURRENT DISC
		#--------------------------------------------
		my $vertRowCount=0;
		for (my $i = 0; $i < ($#discArray+1) ; $i++)
		{
			lx("select.drop vertex");
			lx("select.element [$mainlayer] vertex add index:@verts[$i]");

			my @moveToPos = lxq("query layerservice vert.pos ? @discArray[$i]");
			lx("vert.set x @moveToPos[0]");
			lx("vert.set y @moveToPos[1]");
			lx("vert.set z @moveToPos[2]");

			#MOVE THE SYMMETRICAL VERTROW
			if ($symmAxis != 3)
			{
				#find the symmetrical Vert
				foreach my $vert (keys %vertPosTable)
				{
					if (($vertPosTable{$vert}[$symmAxis] == (($vertPosTable{@verts[$i]}[$symmAxis])*-1)) && ($vertPosTable{$vert}[$nonSymmAxis1] == ($vertPosTable{@verts[$i]}[$nonSymmAxis1])) && ($vertPosTable{$vert}[$nonSymmAxis2] == ($vertPosTable{@verts[$i]}[$nonSymmAxis2])))
					{
						#lxout("$vert matches @verts[$i]");

						#remove this symm vertrow from the vertRowList
						if ($skipRow{$vertRowCount} != 1)
						{
							#find the symm vertRow
							for (my $i = 0; $i<@vertRowList; $i++)
							{
								#lxout("Trying to find which vertRow $vert is in");
								if (@vertRowList[$i]=~ /\b$vert\b/)
								{
									#lxout("This is it : @vertRowList[$i]");
									$skipRow{$i} = 1;
									$vertRowCount = $i;
									last;
								}
							}
						}

						#move the symmetrical vert.
						lx("select.drop vertex");
						lx("select.element [$mainlayer] vertex add index:$vert");
						if ($symmAxis == 0) 	{	lx("vert.set x (@moveToPos[0]*-1)");	}
						else				{	lx("vert.set x @moveToPos[0]");		}
						if ($symmAxis == 1) 	{	lx("vert.set y (@moveToPos[1]*-1)");	}
						else				{	lx("vert.set y @moveToPos[1]");		}
						if ($symmAxis == 2) 	{	lx("vert.set z (@moveToPos[2]*-1)");	}
						else				{	lx("vert.set z @moveToPos[2]");		}
					}
				}
			}
		}


		#--------------------------------------------
		#SELECT THE (CURRENT) DISC AND DELETE IT
		#--------------------------------------------
		lx("select.drop vertex");
		foreach my $vert(@discArray) { lx("select.element [$mainlayer] vertex add index:$vert"); }
		lx("delete");
	}
	#else
	#{
		#lxout("Skipping row [$j] (@vertRowList[$j]) because it's a symmetrical row");
	#}
}





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#Set the workplane back
if ((@backupWP[0] == 0) && (@backupWP[1] == 0) && (@backupWP[2] == 0) && (@backupWP[3] == 0) && (@backupWP[4] == 0) && (@backupWP[5] == 0))
{
	lxout("RESETTING THE WORKPLANE");
	lx("workplane.reset");
}
else
{
	lxout("PUTTING THE ORIGINAL (CUSTOM) WORKPLANE BACK");
	lx("workplane.reset");
	lx("workPlane.edit [@backupWP[0]] [@backupWP[1]] [@backupWP[2]] [@backupWP[3]] [@backupWP[4]] [@backupWP[5]]");
}

#Put the UNIT SYSTEM back : (fixed for modo2)
if ($unitSys ne "metric"){
	lx("pref.value units.system $unitSys");
}

#Set the DEFAULT UNIT back : (fixed for modo2)
if ($prefUnit ne "meters"){
	lx("pref.value units.default $prefUnit");
}

#Set the selection settings back
lx("select.type $sel_type");

#Set the symmetry mode back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";	}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------------SUBROUTINES---------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------



#-----------------------------------------------------------------------------------------------------------
#DIST check subroutine
#-----------------------------------------------------------------------------------------------------------
sub distance
{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my $dist = sqrt(($disp0*$disp0)+($disp1*$disp1)+($disp2*$disp2));
	return $dist;
}



#-----------------------------------------------------------------------------------------------------------
#cheap DIST check subroutine
#-----------------------------------------------------------------------------------------------------------
sub fakeDistance
{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my $fakeDist = (abs($disp0)+abs($disp1)+abs($disp2));
	return $fakeDist;
}



#-----------------------------------------------------------------------------------------------------------
#popup subroutine
#-----------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}



#-----------------------------------------------------------------------------------------------------------
#sort Rows subroutine
#-----------------------------------------------------------------------------------------------------------
sub sortRow()
{
	#this first part is stupid.  I need it to loop thru one more time than it will:
	my @loopCount = @origEdgeList_edit;
	unshift (@loopCount,1);
	#lxout("How many fucking times will I go thru the loop!? = $#loopCount");

	foreach(@loopCount)
	{
		#lxout("[->] USING sortRow subroutine----------------------------------------------");
		#lxout("original edge list = @origEdgeList");
		#lxout("edited edge list =  @origEdgeList_edit");
		#lxout("vertRow = @vertRow");
		my $i=0;
		foreach my $thisEdge(@origEdgeList_edit)
		{
			#break edge into an array  and remove () chars from array
			@thisEdgeVerts = split(/,/, $thisEdge);
			#lxout("-        origEdgeList_edit[$i] Verts: @thisEdgeVerts");

			if (@vertRow[0] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[0] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			else
			{
				$i++;
			}
		}
	}
}




