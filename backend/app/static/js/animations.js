function flipCard() {

    const card = document.getElementById("drawCard");

    if (!card) return;

    card.classList.remove("flipped");
    card.classList.remove("shuffling");

    void card.offsetWidth;

    card.classList.add("shuffling");

    setTimeout(() => {

        card.classList.remove("shuffling");
        card.classList.add("flipped");

    },1200);

}

function launchConfetti(){

    const container=document.getElementById("confettiContainer");

    if(!container)return;

    container.innerHTML="";

    const emojis=[
        "🎉",
        "❤️",
        "✨",
        "💕",
        "💜",
        "🥳"
    ];

    for(let i=0;i<80;i++){

        const piece=document.createElement("div");

        piece.className="confetti-piece";

        piece.innerHTML=emojis[Math.floor(Math.random()*emojis.length)];

        piece.style.left=Math.random()*100+"%";

        piece.style.animationDelay=Math.random()*0.5+"s";

        piece.style.fontSize=(18+Math.random()*20)+"px";

        container.appendChild(piece);

    }

    setTimeout(()=>{

        container.innerHTML="";

    },3500);

}

function showToast(message,color="#6C5CE7"){

    let toast=document.getElementById("toast");

    toast.innerHTML=message;

    toast.style.background=color;

    toast.classList.add("show");

    setTimeout(()=>{

        toast.classList.remove("show");

    },2500);

}