within ThermofluidStream.Sensors;
model SingleSensorX "Sensor for mass fraction of mixture"

  import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;

  replaceable package Medium = Media.myMedia.Interfaces.PartialMedium
    "Medium model"
    annotation (choicesAllMatching=true,
      Documentation(info="<html>
        <p>Medium Model for the sensor. Make sure it is the same as for all lines the sensors input is connected.</p>
        </html>"));

  parameter Integer digits(min=0) = 1 "Number of displayed digits";
  parameter Boolean outputValue = false "Enable sensor-value output"
    annotation(Dialog(group="Output Value"));
  parameter Boolean filter_output = false "Filter sensor-value to break algebraic loops"
    annotation(Dialog(group="Output Value", enable=outputValue));
  parameter SI.Time TC = 0.1 "PT1 time constant"
    annotation(Dialog(tab="Advanced", enable=outputValue and filter_output));
  parameter InitMode init=InitMode.steadyState "Initialization mode for sensor lowpass"
    annotation(choicesAllMatching=true, Dialog(tab="Initialization", enable=filter_output));
  parameter Real[Medium.nX] value_0(each unit="kg/kg") = Medium.X_default "Initial output state of sensor"
    annotation(Dialog(tab="Initialization", enable=filter_output and init==InitMode.state));
  parameter Integer row(min=1, max=Medium.nX) = 1 "Row of mass fraction vector to display";

  Interfaces.Inlet inlet(redeclare package Medium=Medium)
    annotation (Placement(transformation(extent={{-20, -20},{20, 20}}, origin={-100,0})));
  Modelica.Blocks.Interfaces.RealOutput value_out[Medium.nX](each unit="kg/kg") = value if outputValue "Measured value [variable]"
    annotation (Placement(transformation(extent={{80,-20},{120,20}})));

  output Real value[Medium.nX](each unit="kg/kg") "Computed value of the selected quantity";
  output Real display_value(unit="kg/kg") = value[row] "Row of the value vector to display";

  function mfk = ThermofluidStream.Utilities.Functions.massFractionK (
    redeclare package Medium = Medium);

protected
  outer DropOfCommons dropOfCommons;

  Real direct_value[Medium.nX](each unit="kg/kg");

initial equation
  if filter_output and init==InitMode.steadyState then
    value= direct_value;
  elseif filter_output then
    value = value_0;
  end if;

equation
  inlet.m_flow = 0;
  for i in 1:Medium.nXi loop
    direct_value[i] = mfk(inlet.state, i);
  end for;
  //direct_value[1:Medium.nXi] = Medium.massFraction(inlet.state);
  if Medium.reducedX then
    direct_value[end] = 1-sum(direct_value[1:Medium.nXi]);
  end if;

  if filter_output then
    der(value) * TC = direct_value-value;
  else
    value = direct_value;
  end if;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-54,24},{66,-36}},
          lineColor={0,0,0},
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Line(
          points={{-100,0},{0,0}},
          color={28,108,200},
          thickness=0.5),
        Rectangle(
          extent={{-60,30},{60,-30}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-60,30},{60,-30}},
          textColor={28,108,200},
          textString=DynamicSelect("value", String(
              display_value,
              format="1."+String(digits)+"f"))),
        Text(
          extent={{-26,22},{60,69}},
          textColor={175,175,175},
          textString="%row. mass-fraction")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>Sensor for measuring mass fraction X. Which row from X to display can be selected by the row parameter.</p>
<p>This sensor can be connected to a fluid stream without a junction.</p>
</html>"));
end SingleSensorX;
