// Run after DOM loads
document.addEventListener("DOMContentLoaded", () => {
    /* ------------------------------
       Smooth Scroll for Navigation
    ------------------------------- */
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener("click", e => {
            const targetId = link.getAttribute("href");
            if (targetId && targetId.length > 1 && document.querySelector(targetId)) {
                e.preventDefault();
                document.querySelector(targetId).scrollIntoView({
                    behavior: "smooth",
                    block: "start"
                });
            }
        });
    });

    /* ------------------------------
       Hero Animation on Load
    ------------------------------- */
    const hero = document.querySelector(".hero-content");
    if (hero) {
        hero.style.opacity = 0;
        hero.style.transform = "translateY(30px)";
        setTimeout(() => {
            hero.style.transition = "all 1s ease";
            hero.style.opacity = 1;
            hero.style.transform = "translateY(0)";
        }, 300);
    }

    /* ----------------------------------------
       Expandable Department Cards (+ toggle)
    ----------------------------------------- */
    const expandButtons = document.querySelectorAll(".expand-btn");
    expandButtons.forEach(btn => {
        btn.addEventListener("click", e => {
            e.stopPropagation();
            const card = btn.closest(".department-card");

            // Create extra info div if not present
            let details = card.querySelector(".department-details");
            if (!details) {
                details = document.createElement("div");
                details.classList.add("department-details");
                details.innerHTML = `
                    <p class="dept-info">Explore books, projects, and archives in this department. Coming soon!</p>
                `;
                details.style.marginTop = "12px";
                details.style.color = "#2d2414";
                details.style.fontSize = "14px";
                details.style.lineHeight = "1.5";
                details.style.display = "none";
                card.appendChild(details);
            }

            // Toggle expansion
            const isExpanded = btn.textContent === "−";
            btn.textContent = isExpanded ? "+" : "−";
            details.style.display = isExpanded ? "none" : "block";

            // Small animation
            details.animate([
                { opacity: 0, transform: "translateY(-5px)" },
                { opacity: 1, transform: "translateY(0)" }
            ], {
                duration: 250,
                fill: "forwards"
            });
        });
    });

    /* -------------------------------------
       Scroll Reveal for Department Cards
    -------------------------------------- */
    const cards = document.querySelectorAll(".department-card");
    const revealOptions = {
        threshold: 0.1
    };

    const revealOnScroll = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.transition = "transform 0.6s ease, opacity 0.6s ease";
                entry.target.style.transform = "translateY(0)";
                entry.target.style.opacity = "1";
                observer.unobserve(entry.target);
            }
        });
    }, revealOptions);

    cards.forEach(card => {
        card.style.opacity = "0";
        card.style.transform = "translateY(30px)";
        revealOnScroll.observe(card);
    });

    /* -------------------------------------
       Button Ripple Effect (optional)
    -------------------------------------- */
    const rippleButtons = document.querySelectorAll(".btn-explore, .expand-btn");
    rippleButtons.forEach(btn => {
        btn.addEventListener("click", function (e) {
            const ripple = document.createElement("span");
            ripple.classList.add("ripple");
            this.appendChild(ripple);

            const size = Math.max(this.offsetWidth, this.offsetHeight);
            ripple.style.width = ripple.style.height = `${size}px`;
            ripple.style.left = `${e.offsetX - size / 2}px`;
            ripple.style.top = `${e.offsetY - size / 2}px`;

            setTimeout(() => ripple.remove(), 600);
        });
    });
});
