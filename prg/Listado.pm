#  Listado.pm - Interfaz para generar listados en PDF
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009
#  Desarrollado a partir del paquete PDF::Report por Andy Orr
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 20.06.2009

package Listado ;

use PDF::API2;

# Valores predeterminados
my %Tipo;
$Tipo{hoja} = 'letter';
$Tipo{orientacion} = 'retrato'; # alternativa 'apaisado'

my %INFO = (Creator => 'Quipu', CreationDate => '', Title => '', 
	Producer => "PDF::API2 $PDF::API2::VERSION", Subject => '', Author => '') ;

# Parámetros que se pueden definir al crear el objeto con "Listado->crea();
my @listaP = qw(hoja orientacion);
my @listaI = qw(CreationDate Title Subject Author);

sub crea {
  my $clase    = shift;
  my %opciones = @_;

  foreach my $dflt (@listaP) { # Lee opciones Tipo
      $Tipo{$dflt} = $opciones{$dflt} if defined( $opciones{$dflt} );
  }
  foreach my $dflt (@listaI) { # Lee opciones INFO
      $INFO{$dflt} = $opciones{$dflt} if defined( $opciones{$dflt} ) ;
  }

  my ($x1,$y1,$ancho,$alto) = PDF::API2::Util::page_size($Tipo{Hoja});

  if (lc($Tipo{orientacion}) eq 'apaisado') {
    my $tempW = $ancho;
    $ancho = $alto;
    $alto = $tempW;
    $tempW = undef;
  }
  my ($mX, $mY) = (50, 30);
  my $obj= { hPos    => undef,
             vPos    => undef,
             cuerpo  => 12 ,
             fuente  => 'Helvetica' ,
             AnchoP  => $ancho,
             AltoP   => $alto,
             margenX    => $mX,
             margenY    => $mY,
             AnchoCaja  => $ancho - $mX,
             AltoCaja   => $alto - $mY * 2,
             pgn     => undef, 
             n_pgn   => 0,
             just    => 'izquierda',
			 sepC => 3,
			 sepV => 0.3,
             grosor  => 0.8,
             __font_cache => {},
            };

  if ( $opciones{archivo} ) {
    $obj->{pdf} = PDF::API2->open($opciones{archivo}) 
                     or die "$opciones{archivo} no existe: $!\n";
    
  } else {
    $obj->{pdf} = PDF::API2->new();
  } 

  # Tipografía predeterminada
  $obj->{fuente} = $obj->{pdf}->corefont('Helvetica', -encode=> 'latin1'); 

  # Opciones adicionales del usuario
  foreach my $key (keys %opciones) {
    $obj->{$key} = $opciones{$key};
  }

  bless $obj ;
  return $obj;
}

# Subrutinas básicas
sub nuevaPgn { # crea una nueva página en blanco
  my $obj = shift;

  $obj->{pgn} = $obj->{pdf}->page;
  $obj->{pgn}->mediabox( $obj->{AnchoP}, $obj->{AltoP} );
  $obj->{n_pgn}++;

  return ;
}

sub grabar {
  my ($obj, $archivo) = @_;

  $obj->{pdf}->info(%INFO);
  $obj->{pdf}->saveas($archivo);
  $obj->{pdf}->end();
}

# Manejo de textos
sub iTexto { # Coloca un texto en la posición $x, $y
  my ($obj, $text, $x, $y, $color, $underline, $indent, $rotate) = @_;

  $color = undef if not $color; # Por defecto color es negro
  $underline = undef if not $underline;
  $indent = undef if not $indent;

  my $txt = $obj->{pgn}->text;

  $txt->textlabel($x, $y, $obj->{fuente}, $obj->{cuerpo}, $text,
  	-rotate => $rotate, -color => $color, -underline => $underline, 
	-indent => $indent);

}

sub sLineas { # Separa líneas de un texto según ancho dado.
  my $obj = shift;
  my $text = shift;
  my $width = shift;

  $text = '' if not $text ;

  return $text if ($text =~ /\n/);  # Texto con saltos de líneas, se mantiene
  return $text unless defined $width; # Se debe proporcionar el ancho del texto
  
  my $txt = $obj->{pgn}->text;
  $txt->font($obj->{fuente}, $obj->{cuerpo});

  my $ThisTextWidth=$txt->advancewidth($text);
  return $text if ( $ThisTextWidth <= $width);

  my $widSpace = $txt->advancewidth('t');

  my $currentWidth = 0;
  my $newText = "";
  foreach ( split / /, $text ) {
    my $strWidth = $txt->advancewidth($_);
    if ( ( $currentWidth + $strWidth ) > $width ) {
      $currentWidth = $strWidth + $widSpace;
      $newText .= "\n$_ ";
    } else {
      $currentWidth += $strWidth + $widSpace;
      $newText .= "$_ ";
    }
  }
  return $newText;
}

sub bloque {
  my ( $obj, $text, $hPos, $textWidth, $textHeight ) = @_;

  my $txt = $obj->{pgn}->text;
  $txt->font($obj->{fuente}, $obj->{cuerpo});

  # Push the margin on for just=left (need to work on just=right)
  if ( ($hPos=~/^[0-9]+([.][0-9]+)?$/) && ($obj->{just}=~ /^izquierda$/i) ) {
    $obj->{hPos} = $hPos + $obj->{margenX};
  }

  # Establish a proper $obj->{hPos} if we don't have one already
  if ($obj->{hPos} !~ /^[0-9]+([.][0-9]+)?$/) {
    if ($obj->{just}=~ /^izquierda$/i) {
      $obj->{hPos} = $obj->{margenX};
    } elsif ($obj->{just}=~ /^derecha$/i) {
      $obj->{hPos} = $obj->{AnchoP} - $obj->{margenX};
    } elsif ($obj->{just}=~ /^centro$/i) {
      $obj->{hPos} = int($obj->{AnchoP} / 2);
    }
  }

  # If the user did not give us a $textWidth, use the distance
  # from $hPos to the right margin as the $textWidth for just=left,
  # use the distance from $hPos back to the left margin for just=right
  if ( ($textWidth !~ /^[0-9]+$/) && ($obj->{just}=~ /^izquierda$/i) ) {
    $textWidth = $obj->{AnchoCaja} - $obj->{hPos} + $obj->{margenX};
  } elsif ( ($textWidth !~ /^[0-9]+$/) && ($obj->{just}=~ /^derecha$/i) ) {
    $textWidth = $obj->{hPos} + $obj->{margenX};
  } elsif ( ($textWidth !~ /^[0-9]+$/) && ($obj->{just}=~ /^centro$/i) ) {
    my $textWidthL=$obj->{AnchoCaja} - $obj->{hPos} + $obj->{margenX};
    my $textWidthR=$obj->{hPos} + $obj->{margenX};
    $textWidth = $textWidthL;
    if ($textWidthR < $textWidth) { $textWidth = $textWidthR; }
    $textWidth = $textWidth * 2;
  }

  # If $obj->{vPos} is not set calculate it (on first text add)
  if ( ($obj->{vPos} == undef) || ($obj->{vPos} == 0) ) {
    $obj->{vPos} = $obj->{AltoP} - $obj->{margenY} - $obj->{cuerpo};
  }

  # If the text has no carrige returns we may need to wrap it for the user
  if ( $text !~ /\n/ ) {
    $text = $obj->sLineas($text, $textWidth);
  }

  if ( $text !~ /\n/ ) {
    # Determine the width of this text
    my $thistextWidth = $txt->advancewidth($text);
	# Ajusta hPos segun alineamiento del texto
    my $xPos=$obj->{hPos};
    if ($obj->{just}=~ /^derecha$/i) {
      $xPos=$obj->{hPos} - $thistextWidth;
    } elsif ($obj->{just}=~ /^centro$/i) {
      $xPos=$obj->{hPos} - $thistextWidth / 2;
    }
    $obj->iTexto($text,$xPos,$obj->{vPos});

    $thistextWidth = -1 * $thistextWidth if ($obj->{just}=~ /^derecha$/i);
    $thistextWidth = -1 * $thistextWidth / 2 if ($obj->{just}=~ /^centro$/i);
    $obj->{hPos} += $thistextWidth;
  } else {
    $text=~ s/\n/\0\n/g;       # This copes w/strings of only "\n"
    my @lines= split /\n/, $text;
    foreach ( @lines ) {
      $text= $_;
      $text=~ s/\0//;
      if (length( $text )) {
        $obj->iTexto($text, $obj->{hPos}, $obj->{vPos});
      }
      if (($obj->{vPos} - $obj->{cuerpo}) < $obj->{margenY}) {
        $obj->{vPos} = $obj->{AltoP} - $obj->{margenY} - $obj->{cuerpo};
        $obj->nuevaPgn();
      } else {
        $textHeight = $obj->{cuerpo} unless $textHeight;
        $obj->{vPos} -= $textHeight ; # Modificado por VAR
#  $obj->{vPos} -= $obj->{cuerpo} - $obj->{linespacing}; ERROR en el original
      }
    }
  }
}

sub parrafo {
  my ( $obj, $text, $hPos, $vPos, $width, $height, $indent, $lead ) = @_;

  my $txt = $obj->{pgn}->text;
  $txt->font($obj->{fuente}, $obj->{cuerpo});

  $txt->lead($lead); # Espacio entre lineas
  $txt->translate($hPos,$vPos);
  $txt->paragraph($text, $width, $height, -align=>'justified');

  ($obj->{hPos}, $obj->{vPos}) = $txt->textpos;
}

sub centrar { 
	my ($obj, $YPos, $texto) = @_;
 
	my $just = $obj->{just} ;
	$obj->{vPos} = $YPos ;
	$obj->{just} = 'centro' ;
	$obj->bloque($texto);
	$obj->{just} = $just ;
  
	return $obj->{vPos} ;
} 

sub saltaLineas {
	my ($obj, $num) = @_;
	
	$obj->{hPos} = $obj->{margenX};
	$obj->{vPos} -= $obj->{cuerpo} * $num ;
	
	return ( $obj->{hPos}, $obj->{vPos} );
}

sub largoTexto {
  my ($obj, $texto) = @_;

  my $txt = $obj->{pgn}->text;
  $txt->font($obj->{fuente}, $obj->{cuerpo});

  return $txt->advancewidth($texto);
}


sub trazo {
  my ( $obj, $x1, $y1, $x2, $y2 ) = @_;

  my $gfx = $obj->{pgn}->gfx;
  $gfx->move($x1, $y1);
  $gfx->linewidth($obj->{grosor});
  $gfx->line($x2, $y2);
  $gfx->stroke;
}

sub rectangulo { 
  my ( $obj, $x1, $y1, $x2, $y2 ) = @_;

  my $gfx = $obj->{pgn}->gfx;
  $gfx->linewidth($obj->{grosor});
  $gfx->rectxy($x1, $y1, $x2, $y2);
  $gfx->stroke;
}


sub rellena {  
  my ( $obj, $x1, $y1, $x2, $y2, $color ) = @_;

  my $gfx = $obj->{pgn}->gfx;

  $gfx->fillcolor($color);
  $gfx->rectxy($x1, $y1, $x2, $y2);
  $gfx->fill;
}

sub lineaH {
  my ( $obj, $x, $ancho, $grosor, $color) = @_;

  my $gfx = $obj->{pgn}->gfx;

  $gfx->linewidth($obj->{grosor});
  $gfx->strokecolor($color) if $color ;
  $gfx->linewidth($grosor) if $grosor ;
  $gfx->move($x, $obj->{vPos});
  $gfx->hline($x+$ancho);
  $gfx->stroke;

}

# Tipografía
sub fuente {
  my ( $obj, $fnt ) = @_;

  if (exists $obj->{__font_cache}->{$fnt}) {
    $obj->{fuente} = $obj->{__font_cache}->{$fnt};
  }
  else {
    $obj->{fuente} = $obj->{pdf}->corefont($fnt);
    $obj->{__font_cache}->{$fnt} = $obj->{fuente};
  }
  $obj->{fontname} = $fnt;
}

sub cuerpo {
  my ( $obj, $tm ) = @_;

  $obj->{cuerpo} = $tm;
}

sub numeroPgn {
  my ($obj, $texto) = @_;

  $obj->{cuerpo} = 10;
  my $y = $obj->{margenY} + $obj->{cuerpo} ;
  $obj->iTexto($texto, $obj->{margenX}, $y, 'grey35') if $texto;
  $obj->iTexto("- $obj->{n_pgn} -", $obj->{AnchoCaja}, $y, 'grey35');
}

# Impresión de registros en una línea  
sub iRegistro {
  my $obj = shift ;
  my $rDatos = shift ; # Texto de columnas por imprimir
  my $raCols = shift ; # Datos de ancho de columnas
  my $rfCols = shift ; # Atributos de las columnas (alineación)
  my $numR = shift ; # Cantidad de registros restantes
  my %atr = @_ ; # Otros atributos
  
  my ($color, @aCols, @fCols, @datos, $col, $anchoC, $anchoT, $alin, $aL);
  @aCols = @{$raCols};
  @fCols = @{$rfCols};
  @datos = @{$rDatos};

  $obj->fuente( $atr{'fuente'} ) if $atr{'fuente'} ;
  $obj->cuerpo( $atr{'cuerpo'} ) if $atr{'cuerpo'} ;
  $color = $atr{'color'};

  $col = $aL = 0 ;
  foreach $texto (@datos) {
    $anchoT = $obj->largoTexto($texto);
	$anchoC = $aCols[$col] ;
  	$aL += $anchoC ;
	$alin = $fCols[$col] ;
	# imprime una columna
    my $xPos=$obj->{hPos};
    if ($alin eq 'derecha') {
      $xPos = $obj->{hPos} + $anchoC - $anchoT - $obj->{sepC};
    } elsif ($alin eq 'centro') {
      $xPos = $obj->{hPos} + $anchoC - $anchoT / 2;
    }
    $obj->iTexto($texto, $xPos, $obj->{vPos}, $color);
    $obj->{hPos} += $anchoC;
	$col += 1 ;
  }
  $obj->{hPos} = $obj->{margenX};
  $obj->{vPos} -= $obj->{cuerpo} * $obj->{sepV} ;
  # imprime una línea de separación entre cada registro
  # o una más gruesa si es el encabezado o el última registro
  if ( $atr{'titulo'} or ( $numR == 0 ) ) { 
	  $obj->{vPos} -= 2 ;
	  $obj->lineaH($obj->{hPos}, $aL) ;
	  $obj->{vPos} -= 2 ;
  } else {
	  $obj->lineaH($obj->{hPos}, $aL, 0.5, 'lightblue') ; 
  }
  $obj->{vPos} -= $obj->{cuerpo};
}

sub iTitulo {
  my ($obj, $texto, $color, $fnte, $cuerpo) = @_;

  $obj->cuerpo($cuerpo);
  $obj->fuente($fnte);
  $obj->{hPos} = $obj->{margenX};
  $obj->iTexto($texto, $obj->{hPos}, $obj->{AltoCaja}, $color);
  $obj->{vPos} = $obj->{AltoCaja} - $obj->{cuerpo};
  $obj->{hPos} = $obj->{margenX};
}

# Fin del paquete
1;
