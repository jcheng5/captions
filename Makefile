all:
	R --quiet -e "renv::restore()"
	Rscript generate_all.R
