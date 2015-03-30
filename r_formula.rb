# -*- coding: utf-8 -*-
class RFormula < Formula
  homepage "http://www.r-project.org"
  url "http://mirrors.nics.utk.edu/cran/src/base/R-3/R-3.1.3.tar.gz"
  md5 "53a85b884925aa6b5811dfc361d73fc4"
  
  module_commands [
                   "unload PE-gnu PE-pgi PE-intel PE-cray",
                   "unload r",
                   "load PE-gnu",
                   "load szip",
                   "load acml/5.3.0",
                   "load sprng",
                   "load netcdf-parallel"
                  ]
  def install
    r_home = "#{prefix}/lib64/R"
    
    confopts = ""
    confopts << " --enable-R-profiling"
    confopts << " --enable-memory-profiling"
    confopts << " --enable-R-shlib"
    confopts << " --enable-BLAS-shlib"
    confopts << " --enable-byte-compiled-packages"
    confopts << " --enable-shared"
    confopts << " --enable-long-double"
    confopts << " --with-readline"
    confopts << " --with-tcltk"
    confopts << " --with-cairo"
    confopts << " --with-libpng"
    confopts << " --with-jpeglib"
    confopts << " --with-libtiff"
    confopts << " --with-system-zlib"
    confopts << " --with-system-bzlib"
    confopts << " --with-system-pcre"
    confopts << " --with-valgrind-instrumentation"
    confopts << " --with-blas"
    confopts << " --with-lapack"
    puts "#{confopts}"
    
    module_list
    system "./configure --prefix=#{prefix} #{confopts}"
    system "make all"
    system "make check"
    system "make install"
    
    # R relies on ISO/IEC 60559 compliance of an external BLAS:
    #      ACML (and MKL) are not compliant so test reg-BLAS.Rout fails in
    #      its handling of NAs: NA * 0 = 0 rather than NA!
    # Two options are available:
    # (1) disable two lines before build as follows:
    #disabled for ACML: stopifnot(identical(z, x %*% t(y)))
    #disabled for ACML: stopifnot(is.nan(log(0) %*% 0))
    # see http://devgurus.amd.com/message/1255852#1255852
    # (2) swap in the library with a symlink after the install:
    if module_is_available?("acml/5.3.0")
      acml_prefix = module_environment_variable("acml/5.3.0", "ACML_DIR")
      acml_lib = "#{acml_prefix}/gfortran64_fma4_mp/lib"
      system "mv #{r_home}/lib/libRblas.so #{r_home}/lib/libRblas.so.keep"
      system "ln -s #{acml_lib}/libacml_mp.so #{r_home}/lib/libRblas.so"
    end
    
    # Install several optional packages, including pbdR for SPMD:
    File.open("pInstall", "w+") do |f|
      f.write <<-EOF.strip_heredoc
        BP <- function()
          {
            ## set utk.edu mirror repository url
            cm <- getCRANmirrors()
            cran <- cm[grep("utk.edu",cm[,"URL"]),"URL"]
            options(repos=cran)

            ## select CRAN packages to install
            pkgs <- c("evir", "ismev", "maps", "ggplot2", "SuppDists", "doMC",
                      "foreach", "snow", "doSNOW", "diptest", "ncdf4",
                      "devtools", "dplyr", "stringr", "reshape2", "Rmpi")
            rnetcdfdir <- system("echo $NETCDF_DIR", intern=TRUE)
            sprngdir <- system("echo $SPRNG_LIB", intern=TRUE)
            sprngdir <- substr(strsplit(sprngdir, split="/include")[[1]][1],
                               3, stop=1000)
            ompidir <- system("echo $OMPI_DIR", intern=TRUE)
            config <- list(ncdf=paste("--with-nc-config=", rnetcdfdir,
                           "/bin/nc-config", sep=""),
                           rsprng=paste("--with-sprng=", sprngdir, sep=""),
                           Rmpi=paste("--with-Rmpi-type=OPENMPI",
                                      " --with-mpi=", ompidir, sep=""))
            install.packages(pkgs=pkgs, configure.args=config)

            # Now install pbdR packages from GitHub:
            library(devtools)
            install_github(repo="wrathematics/RNACI") 
            install_github(repo="RBigData/pbdMPI") 
            install_github(repo="RBigData/pbdSLAP") 
            install_github(repo="RBigData/pbdNCDF4") 
            install_github(repo="RBigData/pbdNCDF4") 
            install_github(repo="RBigData/pbdBASE") 
            install_github(repo="RBigData/pbdDMAT") 
            install_github(repo="RBigData/pbdDEMO")
          }
        BP()
      EOF
    end
    system "#{r_home}/bin/Rscript pInstall"
 
  end
  
  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    # R with parallel support
    set version <%= @package.version %>
    proc ModulesHelp { } {
       puts stderr "Sets up environment to use R $version with ACML."
       puts stderr "Interactive Use:   R"
       puts stderr "Parallel Batch Use (see r-pbd.org) via mpirun Rscript"
    }

    module swap PE-intel PE-gnu
    puts stderr "module swap PE-intel PE-gnu"
    module load acml
    module list
    set ompidir {$OMPI_DIR}
    
    set machine redhat6
    set rdir /sw/$machine/r/$version/rhel6_gnu4.7.1
    set rhome $rdir/lib64/R
    
    prepend-path PATH             $rhome/bin
    prepend-path LD_LIBRARY_PATH  $ompidir/lib
    prepend-path LD_LIBRARY_PATH  $rhome/lib
    prepend-path INCLUDE_PATH     $rhome/include
    setenv OMP_NUM_THREADS 1

    puts stderr "Parallel Batch Use (see r-pbd.org) via mpirun Rscript."
    puts stderr "OMP_NUM_THREADS set to 1. Change as needed to use ACML."
  MODULEFILE
end
