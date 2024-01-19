// function myFunction() {
//     // Declare variables
//     var input, filter, ul, li, a, i, txtValue;
//     input = document.getElementById('myInput');
//     filter = input.value.toUpperCase();
//     ul = document.getElementById("myUL");
//     li = ul.getElementsByTagName('li');
  
//     // Loop through all list items, and hide those who don't match the search query
//     for (i = 0; i < li.length; i++) {
//       a = li[i].getElementsByTagName("a")[0];
//       txtValue = a.textContent || a.innerText;
//       if (txtValue.toUpperCase().indexOf(filter) > -1) {
//         li[i].style.display = "";
//       } else {
//         li[i].style.display = "none";
//       }
//     }
//   }

// var countdown = document.getElementById("countdown");
// var initialValue = parseInt(localStorage.getItem("countdown")) || 20000;
// countdown.setAttribute("value", initialValue);
// countdown.innerHTML = initialValue + " seconds";
// var timer = setInterval(function() {
//   var value = parseInt(countdown.getAttribute("value"));
//   value--;
//   countdown.setAttribute("value", value);
//   countdown.innerHTML = value + " seconds";
//   localStorage.setItem("countdown", value);
//   if (value == 0) {
//     clearInterval(timer);
//     countdown.innerHTML = "Time's up!";
//   }
// }, 1000);

var countdownDays = document.getElementById("countdown-days");
var countdownHours = document.getElementById("countdown-hours");
var countdownMinutes = document.getElementById("countdown-minutes");
var countdownSeconds = document.getElementById("countdown-seconds");
var targetDate = new Date("2023-06-05T23:59:59"); // Set the target date and time here
var timer = setInterval(function() {
  var now = new Date();
  var remainingTime = Math.max(targetDate - now, 0);
  var seconds = Math.floor(remainingTime / 1000) % 60;
  var minutes = Math.floor(remainingTime / (1000 * 60)) % 60;
  var hours = Math.floor(remainingTime / (1000 * 60 * 60)) % 24;
  var days = Math.floor(remainingTime / (1000 * 60 * 60 * 24));
  countdownDays.innerHTML = days;
  countdownHours.innerHTML = hours;
  countdownMinutes.innerHTML = minutes;
  countdownSeconds.innerHTML = seconds;
  if (remainingTime == 0) {
    clearInterval(timer);
    countdownDays.innerHTML = "0";
    countdownHours.innerHTML = "0";
    countdownMinutes.innerHTML = "0";
    countdownSeconds.innerHTML = "0";
  }
}, 1000);

function submitReview() {
    var name = document.getElementById("name").value;
    var rating = document.querySelector('input[name="rating"]:checked').value;
    var review = document.getElementById("review").value;
    var table = document.getElementById("reviewTable");
    var row = table.insertRow(-1);
    var cell1 = row.insertCell(0);
    var cell2 = row.insertCell(1);
    var cell3 = row.insertCell(2);
    cell1.innerHTML = name;
    cell2.innerHTML = rating;
    cell3.innerHTML = review;
}

var i = 0;
var txt = 'Search your favourite song!'; /* The text */
var speed = 50; /* The speed/duration of the effect in milliseconds */

function typeWriter() {
  if (i < txt.length) {
    document.getElementById("demo").innerHTML += txt.charAt(i);
    i++;
    setTimeout(typeWriter, speed);
  }
}

var searchbar = document.getElementsByClassName("form_search")[0];
var close = document.querySelector(".clear_icon");
var clear_icon = document.getElementsByClassName("clear_icon")[0];
var search_icon = document.getElementsByClassName("search_icon")[0];
var search_results = document.getElementsByClassName("search_results")[0];
var clear_dur = document.getElementsByClassName("clear_durations")[0];
var duration = document.getElementsByClassName("duration")[0];
var duration_range = document.getElementById("duration-range");
var clearAll = document.getElementsByClassName("clearAll")[0];
var explicit = document.getElementById("explicitness");
var search_head = document.getElementById("demo")
function search(){
    if(searchbar.value.length > 0){
        close.style.display = "block";
        var inp = searchbar.value;
        fetch(`https://itunes.apple.com/search?term=`+encodeURIComponent(inp)+`&entity=song&media=music`)
        .then(response => response.json())
        .then(data => {
            search_results.innerHTML = "";
            console.log(data.results);
            var count = 0;
            for(let i=0; count<10 && i<data.resultCount; i++){
                const result = data.results[i];
                console.log(duration_range.value)
                if(result.trackTimeMillis <= (duration_range.value)*1000){
                    if(explicit.checked || result.collectionExplicitness === "notExplicit"){
                        const new_result = document.createElement('div');
                        new_result.classList.add('result_item');
                        const resultImg = document.createElement('img');
                        resultImg.classList.add('result_image');
                        resultImg.src = result.artworkUrl100;
                        resultImg.alt = result.collectionName;
                        const resultTitle = document.createElement('div');
                        resultTitle.classList.add('result_title');
                        resultTitle.textContent = `Song: ${result.trackName}`;
                        const resultAlbum = document.createElement('div');
                        resultAlbum.classList.add('rresult_album');
                        resultAlbum.textContent = `Album: ${result.collectionName}`
                        const resultArtist = document.createElement('div');
                        resultArtist.classList.add('result_artist');
                        resultArtist.textContent = `Artist: ${result.artistName}`;
                        const resultAudio = document.createElement('audio');
                        resultAudio.classList.add('result_audio');
                        resultAudio.src = result.previewUrl;
                        resultAudio.type = "audio";
                        resultAudio.controls = true;
                        new_result.appendChild(resultImg);
                        new_result.appendChild(resultTitle);
                        new_result.appendChild(resultAlbum);
                        new_result.appendChild(resultArtist);
                        new_result.appendChild(resultAudio);
                        search_results.appendChild(new_result);
                        count += 1;
                    }
                }
                else{
                    search_results.innerHTML = "";
                    close.style.display = "none";
                }
            }

        })
        .catch(error => console.error(error));
    }
    else{
        search_results.innerHTML = "";
        close.style.display = "none";
    }
}

searchbar.addEventListener("input", search)
searchbar.addEventListener("keypress", function(event){
    if(event.key === "Enter"){
        event.preventDefault();
        search();
    }
})
close.addEventListener("click", ()=>{
    searchbar.value = "";
    search_results.innerHTML = "";
    close.style.display = "none";
})

search_icon.addEventListener("click", ()=>{

})

var slide = document.getElementById("duration-range");
var display = document.getElementsByClassName("duration")[0];
slide.addEventListener("input", ()=>{
    let dur = slide.value;
    let min = dur/60;
    min = Math.floor(min);
    dur = dur%60;
    let sec = dur;
    if(sec%10!=sec){
        display.innerHTML = `${min}:${sec}`;
    }
    else{
        display.innerHTML = `${min}:0${sec}`
    }
    search();
})

clear_dur.addEventListener("click", ()=>{
    duration_range.value = 600;
    duration.innerHTML = "10:00";
    clear_dur.style.display = "none";
    search();
})

duration_range.addEventListener("input", ()=>{
    clear_dur.style.display = "block";
    if(duration.innerHTML == "10:00"){
        clear_dur.style.display = "none";
    }
    search();
})

clearAll.addEventListener("click", ()=>{
    duration_range.value = 600;
    duration.innerHTML = "10:00";
    clear_dur.style.display = "none";
    explicit.checked = false;
    search();
})

search_head.addEventListener("click", typeWriter())