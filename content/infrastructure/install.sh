#!/bin/sh


conda update conda
conda config --add channels conda-forge
conda create --name gds -y python=3 pandas numpy matplotlib bokeh seaborn scikit-learn jupyter
conda install --name gds -y geopandas==0.8.2 mplleaflet datashader==0.12.0 geojson cartopy==0.18 folium==0.12.1
