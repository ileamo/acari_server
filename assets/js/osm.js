import L from "leaflet"
import {
  GeoSearchControl,
  OpenStreetMapProvider
} from 'leaflet-geosearch';


let osm = document.getElementById("osm")

if (osm) {
  console.log(osm.dataset, osm.dataset.setlocation)
  let prevPos = {
    lat: osm.dataset.latitude,
    lng: osm.dataset.longitude
  }

  const mymap = L.map('osm').setView([prevPos.lat, prevPos.lng], 13);

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaWxlYW1vIiwiYSI6ImNqeDRwMDF6djAxZ2I0NW82aWY0cnRyNmkifQ.KHGb6ZXaBpVWPsFJb3f5IQ', {
    maxZoom: 18,
    attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
      '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
      'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
    id: 'mapbox.streets'
  }).addTo(mymap);

  mymap.attributionControl.setPrefix(false);

  let marker = L.marker([prevPos.lat, prevPos.lng], {
    draggable: osm.dataset.setlocation ? 'true' : false
  });

  if (osm.dataset.setlocation) {
    const provider = new OpenStreetMapProvider();
    const searchControl = new GeoSearchControl({
      provider: provider,
      autoComplete: true, // optional: true|false  - default true
      autoCompleteDelay: 250, // optional: number      - default 250
      style: 'bar',
    });
    mymap.addControl(searchControl);

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
      }
    });

  }

  mymap.addLayer(marker);
}
