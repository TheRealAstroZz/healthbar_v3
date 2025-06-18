window.addEventListener('message', function (event) {
  const data = event.data;

  if (data.type === 'updateHealthBar') {
    let id = `bar-${data.entityId}`;
    let bar = document.getElementById(id);

    if (!bar) {
      bar = document.createElement('div');
      bar.id = id;
      bar.className = 'healthbar';
      bar.innerHTML = `
        <div class="label">${getLabelIcon(data.label)} ${data.label || ''}</div>
        <div class="bar"><div class="fill"></div></div>
      `;
      document.getElementById('healthbars').appendChild(bar);
    }

    const percentage = Math.max(0, Math.min(100, (data.currentHealth / data.maxHealth) * 100));
    const fill = bar.querySelector('.fill');
    fill.style.width = `${percentage}%`;
    fill.style.backgroundColor = getHealthColor(percentage);

    bar.style.left = `${data.x - 50}px`;
    bar.style.top = `${data.y - 60}px`;
    bar.style.display = 'block';

    if (bar.classList.contains('fade-out')) {
      bar.classList.remove('fade-out');
    }

  } else if (data.type === 'hideHealthBar') {
    const bar = document.getElementById(`bar-${data.entityId}`);
    if (bar) {
      bar.classList.add('fade-out');
      setTimeout(() => bar.remove(), 400);
    }

  } else if (data.type === 'floatingDamage') {
    const dmg = document.createElement('div');

    if (data.crit && data.amount <= 0) {
      // Headshot ohne Schaden → Icon
      dmg.className = 'damage-float icon';
      dmg.innerHTML = '<i class="fas fa-crosshairs"></i>';
    } else {
      dmg.className = 'damage-float';
      dmg.textContent = `-${data.amount || '0'}`;
      dmg.style.color = data.color || '#ffffff';

      if (data.crit) {
        dmg.classList.add('crit');
      }
    }

    dmg.style.left = `${data.x || 50}px`;
    dmg.style.top = `${data.y || 50}px`;
    document.body.appendChild(dmg);
    setTimeout(() => dmg.remove(), 1000);

  } else if (data.type === 'headshotKill') {
    const hs = document.createElement('div');
    hs.className = 'headshot-float';
    hs.innerHTML = '<i class="fas fa-skull-crossbones"></i> HEADSHOT!';
    hs.style.left = `${data.x}px`;
    hs.style.top = `${data.y}px`;

    document.body.appendChild(hs);
    setTimeout(() => hs.remove(), 1200);
  }
});

function getHealthColor(percent) {
  const r = percent < 50 ? 255 : Math.floor(255 - (percent * 2.55));
  const g = percent > 50 ? 255 : Math.floor(percent * 5.1);
  return `rgb(${r},${g},0)`;
}

function getLabelIcon(label) {
  switch (label) {
    case "Boss": return "<i class='fas fa-crown'></i>";
    case "Begleiter": return "<i class='fas fa-paw'></i>";
    case "Zombie": return "<i class='fas fa-skull'></i>";
    case "Animal": return "<i class='fas fa-dog'></i>";
    default: return "<i class='fas fa-user'></i>";
  }
}
