const form = document.getElementById("form")

form.addEventListener("submit", event=>{
    const data = new FormData(form) // capture form data
    const url = "/submit-form" //URL to send the request to

    fetch(url, {
        method: "POST",
        body: data,
    })
    .then(response => response.json())
    .catch(error => console.error(error));
})