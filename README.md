Quipu
=====

Un sistema de control de gestión para pequeñas empresas, basado en la 
contabilidad.

###Acerca del nombre

*Quipu* es un sistema de registro estadístico y contable utilizado por los 
Incas antes de la llegada de los españoles. Consiste en un grupo de cuerdas de
colores --cada una con distinta cantidad de nudos-- que están amarradas a una
cuerda principal; se usaba en combinación con el ábaco, que permitía efectuar 
los cálculos aritméticos. 

Por cierto se trata de un sistema algo más antiguo que la *partida 
doble* desarrollada por Luca Paccioli, en la misma época en que Cristobal
Colón llegaba al llamado 'Nuevo Continente'. 

La palabra *quipu* significa *nudo* en quechua; también se suele escribir *kipu*, 
ya que en castellano se pronuncian igual. Sobre este interesante sistema de 
registro y en general sobre la cultura inca, visitar el siguiente [sitio][ref] 
para más información. 

   [ref]: http://incas.perucultural.org.pe/histec2.htm


##Descripción

Este programa está basado en las condiciones legales existentes en Chile,
en especial respecto de las normas tributarias. Pero su propósito explícito
es usar la contabilidad como una efectiva herramienta de control.

Se trata de aprovechar el obligado registro de la documentación
mercantil (facturas, boletas, notas de débito y crédito y otros documentos) para 
registrar información adicional necesaria en el control de las gestión de la pequeñas
empresas.

El programa está diseñado para lograr el control de los documentos que 
reflejan las transacciones de la empresa en combinación con un apropiado
plan de cuentas.

##Requisitos

+ Perl 5.8 o superior
+ Tk804
+ Módulos Perl 
  - DBD::SQLite
  - Tk::TableMatrix
  - Tk::BrowseEntry
  - Date::Simple
  - Number::Format
  - PDF::API2
+ Cualquier sistema operativo que soporte lo anterior.


##Instalación, configuracion y uso

### Requerimientos previos

+ Tener instalados todos los programas definidos como *Requisitos*
+ Disponer del programa *git*. En el sitio [github][] se pueden consultar
las guías sobre cómo instalarlo en los distintos sistemas operativos. En  
el caso de Linux están disponibles las interfaces gráficas que permiten 
instalar paquetes y programas.


   [github]: http://github.com/guides/home


### Descargar el programa

Conectado a Intermet, ejecutar el siguiente comando, desde un terminal o consola: 

	git clone git://github.com/varaya/Quipu.git
	
De esta manera se baja el programa y se crea el directorio *Quipu*, dentro
del directorio en donde se ejecutó el programa. Para seguir con el proceso, 
ejecutar 

	cd Quipu

### Otro método de instalación

También se puede instalar el programa descargando un archivo comprimido desde 
esta página ( http://github.com/varaya/Quipu ), presionando el botón 
**Download Source**. AL descomprimirlo, se crea el directorio Quipu y se continúa
el proceso de instalación y configuración.


### Verificar los requisitos

Luego de haber cambiado de directorio, ejecutar el comando

	perl modulos.pl
	
Esto permitirá verificar que estén instalados todos los módulos Perl que
necesita el programa *Quipu*. Si falta alguno, deberá ser instalado antes 
de seguir con la configuración. Se puede usar el programa `cpan` o alguna
interfaz gráfica disponible en el sistema operativo.

### Configuración inicial

Para usar el programa es necesario crear previamente una empresa y definir 
un plan de cuentas. Esto se realiza en las siguientes etapas:

Primero, con el comando Linux

	./configurar.pl &

se accede a una ventana que pemite registrar datos básicos (año inicial,
tasa del IVA) y crear la empresa, indicando RUT (en formato de números sin
punto, guión y dígito verificador) y nombre de la empresa.

Una vez creada la empresa, completar sus datos: activando el botón **Configura** 
aparece una nueva ventana con tres pestañas; lo más importante es definir que 
controles se quieren activar, haciendo las marcas correspondientes en la pestaña
**Opciones**, ya que ello determina las funciones que deben aparecer en los
menus del programa central.

Segundo, con el comando 

	./central.pl &
	
se entra la programa principal para completar la configuración inicial,
mediante la siguientes acciones:

1. Crear el plan de cuentas, que se compone de cuentas y subgrupos de cuentas. 
Están predefinidos los grandes grupos (Activo, Pasivo, Ingresos y Gastos) y
un conjunto de subgrupos indispensables. Como absoluto mínimo deben existir las 
siguientes cuentas (se indica el subgrupo; los nombres son indicativos y se pueden
modificar):

	> + Caja (10)
	> + Clientes (11)
	> + IVA Crédito Fiscal (11)
	> + Proveedores (20)
	> + IVA Débito Fiscal (20)
	> + Capital (22)
	> + Resultado del Ejercicio (22)
	> + Ingresos por venta (30)
	> + Costos de ventas (40)

2. Registrar los datos de las cuentas a las que se imputa el monto total
y el IVA, de las facturas de compra (Proveedores e IVA Crédito) y de venta 
(Clientes e IVA Débito): opción de menú **Registra - Documento**. De esta 
manera se facilita la contabilización de dichos documentos.

Tercero: si se trata de una empresa que ya tiene una contabilidad, hay que 
efectuar una primera apertura; para ello usar el comando  

	./apertura.pl &

Este permite para ingresar los saldos iniciales y los documentos pendientes 
de pago al inicio del periodo. Previamente se deben ingresar los datos de
Clientes, Proveedores y Prestadores de Servicio (ver más abajo).


### Uso del programa

El programa se inicia, desde el directorio *Quipu*, con el comando:

	./central.pl &

Se puede crear un icono en el escritorio, siguiendo los procedimientos 
usuales del sistema operativo en que se instala el programa.

Para agregar nuevas empresas, se usa el comando 

	./configurar.pl &
	
y se completan sus datos, según lo indicado más arriba.

Previo al ingreso de los documentos por contabilizar supone deben estar registrados
los datos básicos de los Clientes, Proveedores y Prestadores de Servicio, 
según corresponda. Ello se realiza mediante la opción **Registra -Terceros**.

Si se marcó la opción *Controla Centros de Costos* en los datos de la empresa, 
será necesario ingresar código y nombre de los centros desde el menú 
**Registra - Centros de Costos**. 

### Actualización del programa

Las actualizaciones del programa se obtienen desde Internet ejecutando 
el comando

	git pull
	
en el directorio *Quipu*. Para estar informado de los cambios realizados 
en el programa, enviar sus datos al correo indicado al final.

### Faltantes

+ Resultados por Centro de Costo; 
+ Balance Clasificado
+ Algunos listados anexos; y
+ Las Ayudas

##Licencia

###Declaración de Principios

Este programa informático no es una mercancía: es libre y gratuito. Por 
tratarse de un programa de código abierto, puede ser modificado, utilizado 
y distribuido en las condiciones, mínimamente restrictivas, definidas en 
esta Licencia.

Los intercambios que pueda generar, quedan sujetos a los principios de 
reciprocidad y retribución del trabajo efectivamente realizado. Por ello,
este programa *no* está sujeto a una transacción mercantil.


###Condiciones de Uso y Distribución

Está permitido:

1. Hacer y entregar copias de este programa sin restricción,
   con la obligación de incluir el presente documento y 
   traspasar a terceros los derechos previstos en esta Licencia.

2. Realizar modificaciones al programa, dejando constancia en 
   los archivos respectivos quién, cómo y cuándo realizó la
   modificación, con la obligación de cumplir alguna de las 
   siguientes condiciones:

	>  a. Dejar las modificaciones libremente disponibles a otros usuarios, enviándolas al autor del programa original.
      
	>  b. Utilizarlas exclusivamente en forma personal o dentro de la organización en la cual se está usando el programa.
      
	>  c. Hacer un acuerdo directo con el autor de este programa.

3. Cobrar un honorario razonable por instalar, configurar y
   dar soporte en el uso de este programa, dejando constancia
   expresa que el código es libre y gratuito.

4. Utilizar las rutinas y algoritmos incluidos en el Programa,
   como parte de otro programa libre y gratuito.

NO está permitido:

1. Vender el programa, como tal. La retribución que se puede
   obtener es por el trabajo propio, no por el producto de un
   trabajo ajeno.

2. Utilizar el programa como parte de otro sistema informático
   sujeto a distribución comercial.


###Limitación de Responsabilidad

Este programa ha sido desarrollado con la idea de ser útil, pero se 
distribuye 'tal como está', sin garantía alguna, ya  sea directa o 
indirecta, respecto de algún uso particular o del rendimiento y calidad 
del trabajo efectuado con él.

(c) Víctor Araya R., 2010 - <varayar@gmail.com>
