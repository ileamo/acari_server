let osm = document.getElementById("osm")

if (osm) {
  console.log(osm.dataset)
  let prevPos = {
    lat: osm.dataset.latitude,
    lng: osm.dataset.longitude
  }

  let mymap = L.map('osm').setView([prevPos.lat, prevPos.lng], 13);

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaWxlYW1vIiwiYSI6ImNqeDRwMDF6djAxZ2I0NW82aWY0cnRyNmkifQ.KHGb6ZXaBpVWPsFJb3f5IQ', {
    maxZoom: 18,
    attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
      '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
      'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
    id: 'mapbox.streets'
  }).addTo(mymap);

  mymap.attributionControl.setPrefix(false);

  let marker = L.marker([prevPos.lat, prevPos.lng], {
    draggable: 'true'
  });

  if (osm.dataset.setlocation) {
    marker.on('dragend', function(event) {
      var position = marker.getLatLng();
      r = confirm("Задать новые координаты(" + position.lat + ", " + position.lng + ")?");
      if (r) {

      } else {
        marker.setLatLng(prevPos, {
          draggable: 'true'
        }).update();
      }
    });

  }

  mymap.addLayer(marker);
}
