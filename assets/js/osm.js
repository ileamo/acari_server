let osm = document.getElementById("osm")

if (osm) {
  console.log(osm)
  let mymap = L.map('osm').setView([55.777594, 37.737926], 13);

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaWxlYW1vIiwiYSI6ImNqeDRwMDF6djAxZ2I0NW82aWY0cnRyNmkifQ.KHGb6ZXaBpVWPsFJb3f5IQ', {
    maxZoom: 18,
    attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
      '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
      'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
    id: 'mapbox.streets'
  }).addTo(mymap);

  let marker = L.marker([55.777594, 37.737926]).addTo(mymap);


  function onMapClick(e) {
    alert("You clicked the map at " + e.latlng);
  }

  mymap.on('click', onMapClick);
}
