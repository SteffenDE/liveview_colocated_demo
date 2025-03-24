
  class TimeAgo extends HTMLElement {
    constructor(){
      super()
      this.attachShadow({mode: "open"})
    }

    connectedCallback(){
      let updateInterval = parseInt(this.getAttribute("every") || "10000")
      this.dateTime = this.getAttribute("at")
      this.render()
      this.interval = setInterval(() => this.render(), updateInterval)
    }

    disconnectedCallback(){ clearInterval(this.interval) }

    render(){
      this.shadowRoot.innerHTML = this.timeToText(new Date(this.dateTime), new Date())
    }

    timeToText(past, now) {
      let seconds = Math.round((now - past) / 1000)
      let minutes = Math.round(seconds / 60)
      let hours = Math.round(minutes / 60)
      let days = Math.round(hours / 24)
      let months = Math.round(days / 30)
      let years = Math.round(months / 12)

      if(seconds < 60){ return `${seconds} seconds ago` }
      else if (minutes < 60){ return `${minutes} minutes ago` }
      else if (hours < 24){ return `${hours} hours ago` }
      else if (days < 30){ return `${days} days ago` }
      else if (months < 12){ return `${months} months ago` }
      else return `${years} years ago`
    }
  }

  customElements.define("time-ago", TimeAgo)
