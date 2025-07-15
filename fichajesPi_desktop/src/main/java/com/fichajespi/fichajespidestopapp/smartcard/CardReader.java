/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.fichajespi.fichajespidestopapp.smartcard;

import com.fichajespi.fichajespidestopapp.MainWindow;
import com.fichajespi.fichajespidestopapp.entity.Fichaje;
import com.fichajespi.fichajespidestopapp.httpClient.RequestSender;
import com.fichajespi.fichajespidestopapp.httpClient.EstimacionFeignController;
import com.fichajespi.fichajespidestopapp.entity.EstimacionHoras;
import feign.Feign;
import feign.gson.GsonDecoder;
import feign.gson.GsonEncoder;
import com.fichajespi.fichajespidestopapp.httpClient.UsuarioFeignController;
import com.fichajespi.fichajespidestopapp.httpClient.UsuarioResponse;
import java.time.LocalDateTime;
import java.awt.Robot;
import java.awt.event.InputEvent;

import java.io.IOException;
import java.math.BigInteger;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;

/**
 *
 * @author alex
 */
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class CardReader extends Thread {

  private MainWindow instance;
  private RequestSender rs;

  private boolean testMode = false;

  public CardReader(MainWindow instance) {
    this(instance, false);
  }

  public CardReader(MainWindow instance, boolean testMode) {
    this.instance = instance;
    this.rs = new RequestSender();
    this.testMode = testMode;
    if (testMode) {
      SwingUtilities.invokeLater(this::mostrarFormularioTest);
    }
  }

  @Override
  public void run() {
    if (testMode) {
      // En modo test, no leer tarjetas
      return;
    }
    while (true) {
      try {
        // Display the list of terminals
        TerminalFactory factory = TerminalFactory.getDefault();
        List<CardTerminal> terminals = factory.terminals().list();
        //System.out.println("Terminals: " + terminals);

        // Use the first terminal
        CardTerminal terminal = terminals.get(0);

        // Connect with the card
        if (terminal.isCardPresent()) {
          //Simulamos un click de ratón para despertar la pantalla si se ha apagado
          Robot robot = new Robot();
          robot.mousePress(InputEvent.BUTTON1_MASK);
          robot.mouseRelease(InputEvent.BUTTON1_MASK);

          Card card = terminal.connect("*");
          //System.out.println("Card: " + card);
          CardChannel channel = card.getBasicChannel();

          // Send test command
          ResponseAPDU response = channel.transmit(new CommandAPDU(new byte[]{
            (byte) 0xFF,
            (byte) 0xCA,
            (byte) 0x00,
            (byte) 0x00,
            (byte) 0x00}));
          //System.out.println("Response: " + response.toString());

          if (response.getSW1() == 0x63 && response.getSW2() == 0x00) {
            //System.out.println("Failed");
          } else {
            //System.out.println("UID: " + bin2hex(response.getData()));
            BigInteger decimal = new BigInteger(bin2hex(response.getData()), 16);
            System.out.println(decimal);
            fichar(decimal.toString());
            // Disconnect the card
            card.disconnect(false);
          }
        }
      } catch (Exception e) {
        //System.out.println("Ouch: " + e.toString());
      }
    }
  }

  private void mostrarFormularioTest() {
    JFrame frame = new JFrame("Modo Pruebas - Fichar Manualmente");
    frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
    frame.setSize(400, 180);
    frame.setLocationRelativeTo(null);
    frame.setAlwaysOnTop(true);

    JPanel panel = new JPanel();
    panel.setLayout(new GridBagLayout());
    GridBagConstraints gbc = new GridBagConstraints();
    gbc.insets = new Insets(5, 5, 5, 5);
    gbc.fill = GridBagConstraints.HORIZONTAL;

    JLabel label = new JLabel("Introduce número de usuario o código de tarjeta:");
    JTextField textField = new JTextField(20);
    JButton btnFichar = new JButton("Fichar");
    JLabel statusLabel = new JLabel("");

    gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
    panel.add(label, gbc);
    gbc.gridy = 1; gbc.gridwidth = 2;
    panel.add(textField, gbc);
    gbc.gridy = 2; gbc.gridwidth = 1;
    panel.add(btnFichar, gbc);
    gbc.gridx = 1; gbc.gridy = 2;
    panel.add(statusLabel, gbc);

    btnFichar.addActionListener(e -> {
      String input = textField.getText().trim();
      if (input.isEmpty()) {
        statusLabel.setText("Campo vacío");
        return;
      }
      statusLabel.setText("Procesando...");
      new Thread(() -> {
        try {
          fichar(input);
          SwingUtilities.invokeLater(() -> {
            statusLabel.setText("Fichaje procesado");
            textField.setText("");
          });
        } catch (Exception ex) {
          SwingUtilities.invokeLater(() -> statusLabel.setText("Error: " + ex.getMessage()));
        }
      }).start();
    });

    textField.addActionListener(e -> btnFichar.doClick());

    frame.getContentPane().add(panel);
    frame.setVisible(true);
  }

  private void fichar(String number) throws InterruptedException, IOException {
    Fichaje fichaje;
    // En ambos modos, el origen será 'tarjeta' para que el backend lo registre igual
    fichaje = rs.sendRequest(number, "tarjeta");
    if (fichaje != null) {
      System.out.println("Fichaje OK");
      instance.changeNumero(number);
      instance.changeNombre(fichaje.getNombreUsuario());
      StringBuilder builder = new StringBuilder();
      builder.append("Hora de ");
      builder.append(fichaje.getTipo());
      builder.append(": ");
      LocalTime dateTime = LocalTime.parse(fichaje.getHora());
      DateTimeFormatter formatterOut = DateTimeFormatter.ofPattern("HH:mm:ss");
      builder.append(dateTime.format(formatterOut));
      instance.changeFichaje(builder.toString());

      // Solo para fichaje de ENTRADA
      if ("ENTRADA".equalsIgnoreCase(fichaje.getTipo())) {
        instance.mostrarSelectorHoras(() -> {
          if (testMode) {
            // Llamar al backend para obtener el id real
            try {
              UsuarioFeignController usuarioClient = Feign.builder()
                .decoder(new GsonDecoder())
                .target(UsuarioFeignController.class, "http://localhost:8080");
              UsuarioResponse usuario = usuarioClient.getIdByNumero(fichaje.getNumeroUsuario());
              if (usuario != null && usuario.id != null) {
                enviarEstimacionYFinalizar(number, usuario.id, instance.getHorasSeleccionadas());
              } else {
                System.err.println("No se pudo obtener usuarioId para la estimación (modo test)");
                instance.ocultarSelectorHoras();
                instance.resetScreen();
              }
            } catch (Exception e) {
              System.err.println("Error consultando usuarioId: " + e.getMessage());
              instance.ocultarSelectorHoras();
              instance.resetScreen();
            }
          } else {
            Long usuarioId = null;
            try {
              usuarioId = Long.parseLong(fichaje.getNumeroUsuario());
            } catch (Exception e) {
              usuarioId = null;
            }
            if (usuarioId != null) {
              enviarEstimacionYFinalizar(number, usuarioId, instance.getHorasSeleccionadas());
            } else {
              System.err.println("No se pudo obtener usuarioId para la estimación");
              instance.ocultarSelectorHoras();
              instance.resetScreen();
            }
          }
        });
      } else {
        CardReader.sleep(3000);
        instance.resetScreen();
      }
    } else {
      instance.changeNumero(number + " no existe");
      CardReader.sleep(5000);
      instance.resetScreen();
    }
  }

  private void enviarEstimacionYFinalizar(String numero, Long usuarioId, double horas) {
    try {
      System.out.println("[DEBUG] Valor de horas seleccionadas: " + horas);
      // Enviar estimación al backend
      // Gson personalizado para serializar LocalDateTime como ISO-8601
      com.google.gson.Gson gson = new com.google.gson.GsonBuilder()
        .registerTypeAdapter(java.time.LocalDateTime.class, new com.google.gson.JsonSerializer<java.time.LocalDateTime>() {
          @Override
          public com.google.gson.JsonElement serialize(java.time.LocalDateTime src, java.lang.reflect.Type typeOfSrc, com.google.gson.JsonSerializationContext context) {
            return new com.google.gson.JsonPrimitive(src.toString());
          }
        })
        .create();
      EstimacionHoras estimacion = new EstimacionHoras(usuarioId, horas, java.time.LocalDateTime.now());
      String jsonEstimacion = gson.toJson(estimacion);
      System.out.println("[DEBUG] JSON enviado al backend: " + jsonEstimacion);
      EstimacionFeignController estimacionClient = Feign.builder()
        .encoder(new GsonEncoder(gson))
        .decoder(new GsonDecoder(gson))
        .target(EstimacionFeignController.class, "http://localhost:8080");
      estimacionClient.crearEstimacion(estimacion);
    } catch (Exception ex) {
      System.err.println("Error enviando estimación: " + ex.getMessage());
    }
    instance.ocultarSelectorHoras();
    instance.resetScreen();
  }

  private String bin2hex(byte[] data) {
    return String.format("%0" + (data.length * 2) + "X", new BigInteger(1, data));
  }

}
