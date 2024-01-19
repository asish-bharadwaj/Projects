const hello = document.getElementById("hello-world-button")
const bold = document.getElementById("bold-button")
const unbold = document.getElementById("unbold-button")
const imageButton = document.getElementsByClassName("next-image-button")[0]
const image = document.getElementById("cookie-image")
const sl = document.getElementById("dark-mode-switch")
const body = document.getElementsByTagName("body")[0]
const newJokeButton = document.getElementById('new-joke');
const jokeDiv = document.getElementById('joke');

hello.addEventListener("click", () => {
    alert("Asish Bharadwaj")
})

bold.addEventListener("click", () =>{
    let paras = document.getElementsByTagName("p")
    for(let i=0; i<paras.length; i++){
        paras[i].style.fontWeight = "bold"
    }
    paras = document.getElementsByTagName("li")
    for(let i=0; i<paras.length; i++){
        paras[i].style.fontWeight = "bold"
    }
})

unbold.addEventListener("click", ()=>{
    let uparas = document.getElementsByTagName("p")
    for(let i=0; i<uparas.length; i++){
        uparas[i].style.fontWeight = "normal"
    }
    uparas = document.getElementsByTagName("li")
    for(let i=0; i<uparas.length; i++){
        uparas[i].style.fontWeight = "normal"
    }
})

imageButton.addEventListener("click", () => {
    if(image.getAttribute("src") == "images/cookie1.jpg"){
        image.setAttribute("src", "images/cookie2.jpg")
    }
    else if(image.getAttribute("src") == "images/cookie2.jpg"){
        image.setAttribute("src", "images/cookie3.jpg")
    }
    else{
        image.setAttribute("src", "images/cookie1.jpg")
    }
})

sl.addEventListener("click", ()=>{
    if(sl.checked){
        body.style.backgroundColor = "grey"
    }
    else{
        body.style.backgroundColor = "#f2f2f2"
    }

})
newJokeButton.addEventListener('click', ()=>{
    fetch('https://official-joke-api.appspot.com/random_joke')
    .then(response => response.json())
    .then(data => {
    jokeDiv.innerHTML = `${data.setup}<br>${data.punchline}`;
    })
    .catch(error => console.error(error));
})
