enum ActListView {
  totalTime,
  eachAct;

  ActListView toggled() => switch (this) {
        ActListView.totalTime => ActListView.eachAct,
        ActListView.eachAct => ActListView.totalTime,
      };
}
