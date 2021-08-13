# Chia-Tools

Small LINUX scripts for Chia farming

---

### Plotfilter

* **plotfilter.sh** -- A script to separate OG plots from NFT plots

#### To use:

* Run the script as-is with `./plotfilter.sh -t /path/to/plots`
* Or install it with `./install.sh`
   * Then use it as an installed program: `plotfilter`
   * This allows you to change to the desired directory, and run the script in the directory you are working in.

> Note: You might want to do a dry-run with the `-n` option first, to verify its behaviour. 

#### What it does:

The script is just a simple automation of the tedious process of scanning your plots with
```
chia plots check -g /path/to/plots -n 5
```
and then checking each plot for a pool key. If a pool key is found, the plot is moved to a new directory. 
The default behaviour is to move the plots into a sub-directory (for faster processing). You can specify a new destination 
with the `-d` option, but copying to different drives or partitions is largely untested, use at your own risk.

---

*More scripts will be added when needed ..*
