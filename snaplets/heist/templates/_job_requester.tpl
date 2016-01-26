<div class="job-requester">

  <h2>Call function</h2>

  <form>
    <input type="text"
           placeholder="reverse" id="fun-name"/>
    <input type="text"
           placeholder="Hello" id="fun-args"/>
    <button class="btn btn-default"
            type="button" id="call-button"
            onclick="callFun()">Call</button>
  </form>

  <br/>

  <h2>Evaluate expression</h2>
  <div class="input-group">
    <input type="text" class="form-control"
           placeholder="Expression..." id="expr-text"/>
    <span class="input-group-btn">
      <button class="btn btn-default" type="button" id="go">Go!</button>
    </span>
  </div>

  <div class="workers">
    <table id="workers">
      
    </table>
  </div>

  <script src="http://cdnjs.cloudflare.com/ajax/libs/bacon.js/0.7.73/Bacon.js"></script>
  <script src="js/job_requester.js"></script>
  <script src="js/list_workers.js"></script>

</div>