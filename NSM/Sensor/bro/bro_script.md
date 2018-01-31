
# Traffic Analysis with bro by bro scirpt

1.  [Intro](#org011c061)
    1.  [Part 1](#orgb48923c)
    2.  [Command line arguments](#orgadcb055)



<a id="org011c061"></a>

# Intro

This notes that recorded I fix to use bro on the NSM system.


<a id="orgb48923c"></a>

## Part 1

    <Title>
    Environment: [Docker] [trybro] [ubuntu-server] [emacs]
    Language [Bro]: [Emacs-Lisp] [Python]
    Emacs-plugin: [Bro-mode] [pcap-mode]

`Dockerfile of Bro-IDS blacktop/bro`
[
Docker](https://hub.docker.com/r/blacktop/bro/)

[-] Make sure you are using Bro 2.5.1 as tag that is bro version.

[-]   create runbro.sh script that whatever you want to name it that is what law allows us to run bro-scripting

**runbro.sh**

    docker run -v $(pwd):/brostuff/ --rm -ti broplatform/bro:2.5.1 /bro/bin/bro $@

Finally, Modify permissions of runbro.sh `chmod +x runbro.sh`

***brostuff***
Dont forget to use `/brostuff/<ScriptNAME>`

Thoes two statements to standard out is the stuff 

    event bro_init()
      {
    print "Hello, World!";
      }
    
    event bro_done()
        {
    print "Goodbye, World!";
        }

     (setq exec-path (append exec-path '("/usr/local/bro/bin:/usr/local/bro/share/broctl/scripts:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/usr/local/MacGPG2/bin:/opt/X11/bin")))
    
      (setenv "PATH" (concat (getenv "PATH") "/usr/local/bro/bin:/usr/local/bro/share/broctl/scripts:/usr/local/bro/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/usr/local/MacGPG2/bin:/opt/X11/bin"))
    
      (setenv "BROPATH" "/usr/local/bro/spool/installed-scripts-do-not-touch/site:/usr/local/bro/spool/installed-scripts-do-not-touch/auto:/usr/local/bro/share/bro:/usr/local/bro/share/bro/policy:/usr/local/bro/share/bro/site")
    
      (add-to-list 'load-path "~/.emacs.d/private/local/bro-mode")
    
      (setq bro-event-bif "/usr/local/bro/share/bro/base/bif/event.bif.bro")
      (setq bro-tracefiles "~/tracefiles")
      (require 'bro-mode)
    
    ;;you should pay attention to distinguishing of directory between own system and NSM

M-x `bro-run` will send the entire buffer as code to bro asking for the tracefile you want to use and the signature file you want use.

Checking you Minibuffer

This website provide a few seamless environment that we can all interrelated to understand and code by interactive Bro tutorial

[Trybro](http://try.bro.org/)


<a id="orgadcb055"></a>

## Command line arguments

-   Execute a specific policy scripts

    Bro -i ens192 local
    bro -i ens192 docker/bro/test.bro

-   replaying sample pcap through Bro with:

    bro –r sample.pcap local 

this command tells bro to process sample.pcap. else keyword "local" asks bro to load
the 'local' script file  which located in /usr/local//bro/share/site/local.bro.

