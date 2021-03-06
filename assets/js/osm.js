import L from "leaflet"
import {
  GeoSearchControl,
  OpenStreetMapProvider,
} from 'leaflet-geosearch';
import "leaflet.awesome-markers"
import "leaflet.fullscreen/Control.FullScreen"
import "leaflet.markercluster/dist/leaflet.markercluster"

let osm = document.getElementById("osm")

if (osm) {
  //console.log(osm.dataset)
  let prevPos = {
    lat: osm.dataset.latitude,
    lng: osm.dataset.longitude
  }

  const mapboxId = "mapbox"
  const osmId = "openstreetmap"
  const satelliteId = "satellite"
  const customId = "custom"


  let mapbox = L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiaWxlYW1vIiwiYSI6ImNqeDRwMDF6djAxZ2I0NW82aWY0cnRyNmkifQ.KHGb6ZXaBpVWPsFJb3f5IQ', {
    tileSize: 512,
    maxZoom: 18,
    zoomOffset: -1,
    mymapindex: mapboxId,
    errorTileUrl: '/images/bogatka-o.png',
    attribution: '© <a href="https://www.mapbox.com/feedback/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    id: 'mapbox/streets-v11'
  })

  let openstreetmap = L.tileLayer(
    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      mymapindex: osmId,
      errorTileUrl: '/images/bogatka-o.png',
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    })


  let satellite_mapLink =
    '<a href="http://www.esri.com/">Esri</a>';
  let satellite_wholink =
    'i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
  let satellite = L.tileLayer(
    'http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      attribution: '&copy; ' + satellite_mapLink + ', ' + satellite_wholink,
      mymapindex: satelliteId,
      errorTileUrl: '/images/bogatka-o.png',
      maxZoom: 18
    })

  const mymap = L.map('osm').setView([prevPos.lat, prevPos.lng], 13);

  var baseLayers = {
    "OpenStreetMap": openstreetmap,
    "Mapbox": mapbox,
    "Satellite": satellite
  };

  let custom = false;
  if (window.acari_server_env.tileLayerProvider) {
    custom = L.tileLayer(
      window.acari_server_env.tileLayerProvider, {
        mymapindex: customId,
        maxZoom: 18,
        errorTileUrl: '/images/bogatka-o.png',
        attribution: window.acari_server_env.tileLayerProvider
      })
    baseLayers["Custom"] = custom;
  }

  L.control.layers(baseLayers).addTo(mymap);

  if (custom && localStorage.getItem("mapProvider") == customId) {
    custom.addTo(mymap);
    localStorage.setItem("mapProvider", customId)
  } else if (localStorage.getItem("mapProvider") == mapboxId) {
    mapbox.addTo(mymap);
    localStorage.setItem("mapProvider", mapboxId)
  } else if (localStorage.getItem("mapProvider") == satelliteId) {
    satellite.addTo(mymap);
    localStorage.setItem("mapProvider", satelliteId)
  } else {
    openstreetmap.addTo(mymap);
    localStorage.setItem("mapProvider", osmId)
  }

  mymap.on('baselayerchange', function(e) {
    localStorage.setItem("mapProvider", e.layer.options.mymapindex)
  });

  mymap.attributionControl.setPrefix(false);
  let markerIconConf = L.AwesomeMarkers.icon({
    markerColor: 'purple',
    prefix: 'fa',
    extraClasses: 'fas',
    icon: 'paw',
    iconColor: '#000000',
  });

  let colors = ['lightgray', 'red', 'orange', 'blue', 'green']
  let markerIcon = colors.map(function(color) {
    return (
      L.AwesomeMarkers.icon({
        markerColor: color,
        prefix: 'fa',
        extraClasses: 'fas',
        icon: 'paw',
        iconColor: '#000000',
      }));
  })

  if (osm.dataset.markers) {
    let clusterIconFn = function(cluster) {
      let markerColorMap = new Map();
      var childCount = cluster.getChildCount();
      var childMarkers = cluster.getAllChildMarkers();
      for (var i = 0; i < childMarkers.length; i++) {
        let mc = childMarkers[i].options.icon.options.markerColor
        let old = markerColorMap.get(mc)
        markerColorMap.set(mc, old && old + 1 || 1)
      }

      if (false) {

        let c = ' marker-cluster-';
        if (markerColorMap.get("red")) {
          c += 'danger';
        } else if (markerColorMap.get("orange")) {
          c += 'warning';
        } else if (markerColorMap.get("blue")) {
          c += 'info';
        } else if (markerColorMap.get("green")) {
          c += 'success';
        } else {
          c += 'grey';
        }

        return new L.DivIcon({
          html: '<div><span>' + childCount + '</span></div>',
          className: 'marker-cluster' + c,
          iconSize: new L.Point(50, 50)
        });

      } else {

        let wb = 100
        let rad = wb / 2
        let sw = 32
        let r = rad - sw / 2
        let p = 2 * 3.14159 * r
        let dash2 = p + 1
        let op = 0.75
        let opc = 1

        let color_map = {
          "red": "#D43E2A",
          "orange": "#F49630",
          "blue": "#38aadd",
          "green": "#71AF26",
          "gray": "#a3a3a3",
          "white": "#ffffff",
        }

        let svg_sector = ""
        let offs = 0
        let bad_value = "gray"
        for (let c of ["red", "orange", "blue", "green"]) {
          let n = markerColorMap.get(c)
          if (n > 0) {
            if (bad_value == "gray") {
              bad_value = c
            }
            let color = color_map[c] || "#808080"
            let dash1 = p * (n / childCount)
            svg_sector = svg_sector +
              `<circle cx="${rad}" cy="${rad}" r="${r}" stroke="${color}" stroke-opacity="${op}" stroke-width="${sw}" fill-opacity="0" stroke-dasharray="${dash1} ${dash2}" stroke-dashoffset="${offs}" />`
            offs = offs - dash1
          }
        }


        let d = p + offs
        if (d < 0) {
          d = 0
        }
        svg_sector = svg_sector +
          `<circle cx="${rad}" cy="${rad}" r="${r}" stroke="grey" stroke-opacity="${op}" stroke-width="${sw}" fill-opacity="0" stroke-dasharray="${d} ${dash2}" stroke-dashoffset="${offs}" />`

        return new L.DivIcon({
          html: `<svg height="50" width="50" viewbox="0 0 ${wb} ${wb}">` +
            svg_sector +
            `<circle cx="${rad}" cy="${rad}" r="${rad - sw}" fill="${color_map[bad_value]}" fill-opacity="${opc}" />` +
            `<text x="${rad}" y="${rad}" font-size="22px" dominant-baseline="middle"  text-anchor="middle" >${childCount}</text>` +
            '</svg>',
          className: '',
          iconSize: new L.Point(50, 50)
        });
      }

    }

    let markerCluster = L.markerClusterGroup({
      iconCreateFunction: clusterIconFn
    });

    let markers;
    let myMapMarkers = new Map();
    global.osmMap = function(events) {
      for (var i = 0; i < events.length; i++) {
        let name = events[i].name
        let marker = myMapMarkers.get(name)
        if (marker) {
          let level = events[i].level
          marker.setIcon(markerIcon[level])
        }
      }
      markerCluster.refreshClusters();
    }

    markers = JSON.parse(decodeURIComponent(osm.dataset.markers))
    for (var i = 0; i < markers.length; i++) {
      let point = markers[i];
      let marker = L.marker([point.lat, point.lng], {
        icon: markerIcon[point.alert || 0],
      })
      //.addTo(mymap);
      marker.bindPopup(point.title)
      myMapMarkers.set(point.name, marker);

      markerCluster.addLayer(marker)
    }

    mymap.addLayer(markerCluster)

    let bounds = JSON.parse(decodeURIComponent(osm.dataset.bounds))
    mymap.fitBounds(bounds)

    mymap.addControl(new L.Control.FullScreen());

  } else {

    let marker = L.marker([prevPos.lat, prevPos.lng], {
      icon: markerIconConf,
      draggable: osm.dataset.setlocation ? 'true' : false
    });
    mymap.addLayer(marker);

    if (osm.dataset.setlocation) {
      const provider = new OpenStreetMapProvider();
      const searchControl = new GeoSearchControl({
        provider: provider,
        autoComplete: true, // optional: true|false  - default true
        autoCompleteDelay: 250, // optional: number      - default 250
        searchLabel: 'Введите адрес',
        keepResult: false,
        marker: { // optional: L.Marker    - default L.Icon.Default
          icon: markerIconConf,
          draggable: false,
        },
        //style: 'bar',
      });
      mymap.addControl(searchControl);
      mymap.on('geosearch/showlocation', function(event) {
        let searchPos = {
          lat: event.location.y,
          lng: event.location.x
        }
        marker.setLatLng(searchPos, {
          draggable: 'true'
        }).update();
        document.getElementById("node_input_lat").value = searchPos.lat;
        document.getElementById("node_input_lng").value = searchPos.lng;
      })

      marker.on('dragend', function(event) {
        var position = marker.getLatLng();
        let r = confirm("Задать новое местоположение?");
        if (r) {
          document.getElementById("node_input_lat").value = position.lat;
          document.getElementById("node_input_lng").value = position.lng;

        } else {
          marker.setLatLng(prevPos, {
            draggable: 'true'
          }).update();
          document.getElementById("node_input_lat").value = prevPos.lat;
          document.getElementById("node_input_lng").value = prevPos.lng;
          mymap.setView([prevPos.lat, prevPos.lng], 13);
        }
      });

    }
  }
}
