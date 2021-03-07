# Install guide

The materials for the workshop and all software packages have been tested on
Python 2 and 3 on the following three platforms:

- Linux (Ubuntu-Mate x64)
- Windows 10 (x64)
- Mac OS X (10.15.9 x64).

The workshop depends on the following libraries/versions:

* `numpy>=1.19.5`
* `pandas>=1.1.5`
* `matplotlib>=3.3.4`
* `jupyter>=1.0`
* `seaborn>=0.11.1`
* `pip>=21.0.1`
* `geopandas>=0.8.2`
* `pysal>=2.4.0`
* `libpysal>=4.4.0`
* `cartopy>=0.18.0`
* `pyproj>=2.6.1`
* `shapely>=1.7.1`
* `geopy>=2.1.0`
* `scikit-learn>=0.17.1`
* `bokeh>2.3.0`
* `mplleaflet>=0.0.5`
* `datashader>=0.12.0`
* `geojson>=2.5.0`
* `folium>=0.12.1`
* `statsmodels>=0.12.2`
* `xlrd>=2.0.1`
* `xlsxwriter>=1.3.7`

## Linux/Mac OS X

1. Install Anaconda
2. Get the most up to date version:

`> conda update conda`

3. Add the `conda-forge` channel:

`> conda config --add channels conda-forge`

4. Create an environment named `gds`:

`> conda create --name gds python=3 pandas numpy matplotlib bokeh seaborn scikit-learn jupyter statsmodels xlrd xlsxwriter`

5. Install additional dependencies:

`> conda install --name gds geojson geopandas mplleaflet datashader cartopy folium`

6. To activate and launch the notebook:

```
> source activate gds

> jupyter notebook
```

## Windows

1. Install
   [Anaconda3-4.0.0-Windows-x86-64](http://repo.continuum.io/archive/Anaconda3-4.0.0-Windows-x86_64.exe)
2. open a cmd window
3. Get the most up to date version:

`> conda update conda`

4. Add the `conda-forge` channel:

`> conda config --add channels conda-forge`

5. Create an environment named `gds`:

`> conda create --name gds pandas numpy matplotlib bokeh seaborn statsmodels scikit-learn jupyter xlrd xlsxwriter geopandas mplleaflet datashader geojson cartopy folium`

6. To activate and launch the notebook:

```
> activate gds

> jupyter notebook
```

# Testing

Once installed, you can run the notebook `test.ipynb` placed under
`content/infrastructure/test.ipynb` to make sure everything is correctly
installed. Follow the instructions in the notebook and, if you do not get any
error, you are good to go.

