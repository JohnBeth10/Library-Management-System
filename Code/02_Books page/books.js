
// Find the button and the text elements by their IDs
const myButton = document.getElementById('notifyButton');
const myButtonText = document.getElementById('notifyText');

// Listen for a click on the button
myButton.addEventListener('click', function() {
// Add the 'clicked' class to the button
myButton.classList.add('clicked');

// Change the text inside the button
myButtonText.innerText = 'Reserved!';
});