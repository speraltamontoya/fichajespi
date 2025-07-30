/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.fichajespi.fichajespidestopapp;

import com.fichajespi.fichajespidestopapp.smartcard.CardReader;
import com.fichajespi.fichajespidestopapp.tools.CurrentDate;
import com.fichajespi.fichajespidestopapp.tools.CurrentTime;
import com.fichajespi.fichajespidestopapp.tools.BackendConfig;
import com.fichajespi.fichajespidestopapp.tools.Logger;

import java.util.Locale;
import java.awt.Dimension;

/**
 *
 * @author alex
 */
public class MainWindow extends javax.swing.JFrame {
  private boolean modoTest = false;
  private javax.swing.JTextField txtUsuarioTest;
  private javax.swing.JButton btnSimularFichaje;
  private Runnable onSimularFichaje;

  private javax.swing.JComboBox<String> comboHoras;
  private javax.swing.JButton btnFichar;
  private javax.swing.Timer timerAutoFichar;
  private Runnable onFichar;
  
  // Control de estado para evitar lecturas múltiples
  private boolean permitirLecturaTarjeta = true;
  /**
   * Creates new form MainWindow2
   */
  public MainWindow() {
    this(false, null);
  }

  public MainWindow(boolean modoTest, Dimension customSize) {
    this.modoTest = modoTest;

    if (customSize != null) {
        setUndecorated(true);  // debe ir antes de initComponents
        setPreferredSize(customSize);
        setSize(customSize);
        setResizable(false);
    }

    initComponents();

    // Configurar ventana para mantenerse siempre en primer plano
    setAlwaysOnTop(true);

    setVisible(true);

    // Inicializar combo y botón y añadirlos a la interfaz de forma centrada
    comboHoras = new javax.swing.JComboBox<>();
    for (double h = 1.0; h <= 12.0; h += 0.25) {
        comboHoras.addItem(String.format(Locale.US, "%.2f", h));
    }
    comboHoras.setSelectedItem("4.00");

    btnFichar = new javax.swing.JButton("Fichar");
    btnFichar.setFont(new java.awt.Font("sansserif", 1, 22));
    btnFichar.addActionListener(e -> {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("MainWindow - Valor seleccionado en comboHoras: " + comboHoras.getSelectedItem());
      if (onFichar != null) onFichar.run();
    });
    comboHoras.setFont(new java.awt.Font("sansserif", 0, 22));
    comboHoras.setVisible(false);
    btnFichar.setVisible(false);

    // Inicializar controles del modo test si es necesario DESPUÉS de crear los controles principales
    if (modoTest) {
        inicializarModoTest();
    }

    // Configurar layout después de crear todos los controles
    configurarLayout();

    // Timer para auto-fichar - IMPORTANTE: 30000ms = 30 segundos
    timerAutoFichar = new javax.swing.Timer(30000, e -> {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Timer auto-fichar ejecutándose después de 30 segundos...");
      if (onFichar != null) {
        try {
          com.fichajespi.fichajespidestopapp.tools.Logger.debug("Ejecutando auto-fichar...");
          onFichar.run();
        } catch (Exception ex) {
          com.fichajespi.fichajespidestopapp.tools.Logger.error("Error en auto-fichar: " + ex.getMessage());
          ex.printStackTrace();
          // Mantener selector visible en caso de error
        }
      } else {
        com.fichajespi.fichajespidestopapp.tools.Logger.warning("onFichar es null, no se puede ejecutar auto-fichar");
      }
    });
    timerAutoFichar.setRepeats(false); // Solo ejecutar una vez
    timerAutoFichar.setCoalesce(true);  // Evitar múltiples eventos
  }

  // Permite a CardReader registrar el callback para el botón de simular fichaje
  public void setOnSimularFichaje(Runnable r) {
    this.onSimularFichaje = r;
  }

  /**
   * Inicializa los controles específicos del modo test
   */
  private void inicializarModoTest() {
    // Crear campo de texto para usuario
    txtUsuarioTest = new javax.swing.JTextField();
    txtUsuarioTest.setFont(new java.awt.Font("sansserif", 0, 18));
    txtUsuarioTest.setText("Introduce ID usuario");
    txtUsuarioTest.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    txtUsuarioTest.setForeground(new java.awt.Color(128, 128, 128));
    
    // Limpiar placeholder al hacer click
    txtUsuarioTest.addFocusListener(new java.awt.event.FocusAdapter() {
      @Override
      public void focusGained(java.awt.event.FocusEvent evt) {
        if (txtUsuarioTest.getText().equals("Introduce ID usuario")) {
          txtUsuarioTest.setText("");
          txtUsuarioTest.setForeground(new java.awt.Color(0, 0, 0));
        }
      }
      
      @Override
      public void focusLost(java.awt.event.FocusEvent evt) {
        if (txtUsuarioTest.getText().trim().isEmpty()) {
          txtUsuarioTest.setText("Introduce ID usuario");
          txtUsuarioTest.setForeground(new java.awt.Color(128, 128, 128));
        }
      }
    });
    
    // Crear botón para simular fichaje
    btnSimularFichaje = new javax.swing.JButton("Simular Fichaje");
    btnSimularFichaje.setFont(new java.awt.Font("sansserif", 1, 18));
    btnSimularFichaje.addActionListener(e -> {
      if (isUsuarioTestValido() && onSimularFichaje != null) {
        com.fichajespi.fichajespidestopapp.tools.Logger.debug("Simulando fichaje para usuario: " + getUsuarioTest());
        onSimularFichaje.run();
      } else {
        com.fichajespi.fichajespidestopapp.tools.Logger.warning("Usuario no válido para simular fichaje");
      }
    });
    
    // Añadir al panel pero mantenerlos ocultos inicialmente
    jPanel1.add(txtUsuarioTest);
    jPanel1.add(btnSimularFichaje);
    
    // En modo test, los controles se manejan mediante ventana emergente, no en la pantalla principal
    txtUsuarioTest.setVisible(false);
    btnSimularFichaje.setVisible(false);
  }

  /**
   * Actualiza el layout para incluir los controles del modo test
   */
  private void configurarLayout() {
    javax.swing.GroupLayout layout = (javax.swing.GroupLayout) jPanel1.getLayout();
    jPanel1.add(comboHoras);
    jPanel1.add(btnFichar);
    
    // Configuración del layout horizontal
    javax.swing.GroupLayout.ParallelGroup horizontalGroup = layout.createParallelGroup(javax.swing.GroupLayout.Alignment.CENTER);
    
    // Grupo para selector de horas
    horizontalGroup.addGroup(layout.createSequentialGroup()
        .addGap(0, 0, Short.MAX_VALUE)
        .addComponent(comboHoras, javax.swing.GroupLayout.PREFERRED_SIZE, 120, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addGap(10)
        .addComponent(btnFichar, javax.swing.GroupLayout.PREFERRED_SIZE, 120, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addGap(0, 0, Short.MAX_VALUE));
    
    // Si está en modo test, añadir controles adicionales
    if (modoTest && txtUsuarioTest != null && btnSimularFichaje != null) {
        horizontalGroup.addGroup(layout.createSequentialGroup()
            .addGap(0, 0, Short.MAX_VALUE)
            .addComponent(txtUsuarioTest, javax.swing.GroupLayout.PREFERRED_SIZE, 200, javax.swing.GroupLayout.PREFERRED_SIZE)
            .addGap(10)
            .addComponent(btnSimularFichaje, javax.swing.GroupLayout.PREFERRED_SIZE, 150, javax.swing.GroupLayout.PREFERRED_SIZE)
            .addGap(0, 0, Short.MAX_VALUE));
    }
    
    // Resto de componentes existentes
    horizontalGroup.addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
        .addComponent(jLabelFichaje)
        .addComponent(jLabelNombre)
        .addComponent(jLabel1)
        .addComponent(jLabelNumero)
        .addComponent(jPanel2));
    
    layout.setHorizontalGroup(horizontalGroup);
    
    // Configuración del layout vertical
    javax.swing.GroupLayout.SequentialGroup verticalGroup = layout.createSequentialGroup()
        .addComponent(jLabel1)
        .addComponent(jPanel2)
        .addComponent(jLabelNombre)
        .addComponent(jLabelFichaje)
        .addGap(10);
    
    // Si está en modo test, añadir controles del modo test
    if (modoTest && txtUsuarioTest != null && btnSimularFichaje != null) {
        verticalGroup.addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
            .addComponent(txtUsuarioTest, javax.swing.GroupLayout.PREFERRED_SIZE, 35, javax.swing.GroupLayout.PREFERRED_SIZE)
            .addComponent(btnSimularFichaje, javax.swing.GroupLayout.PREFERRED_SIZE, 35, javax.swing.GroupLayout.PREFERRED_SIZE));
        verticalGroup.addGap(10);
    }
    
    // Añadir controles de horas
    verticalGroup.addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
        .addComponent(comboHoras, javax.swing.GroupLayout.PREFERRED_SIZE, 40, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addComponent(btnFichar, javax.swing.GroupLayout.PREFERRED_SIZE, 40, javax.swing.GroupLayout.PREFERRED_SIZE));
    
    verticalGroup.addComponent(jLabelNumero)
        .addGap(0, 0, Short.MAX_VALUE);
    
    layout.setVerticalGroup(verticalGroup);
  }

  /**
   * Métodos para el modo test
   */
  public void mostrarControlesTest() {
    if (modoTest && txtUsuarioTest != null && btnSimularFichaje != null) {
      txtUsuarioTest.setVisible(true);
      btnSimularFichaje.setVisible(true);
      jLabelFichaje.setText("Modo Test - Introduce usuario");
    }
  }

  public void ocultarControlesTest() {
    if (txtUsuarioTest != null && btnSimularFichaje != null) {
      txtUsuarioTest.setVisible(false);
      btnSimularFichaje.setVisible(false);
    }
  }

  public boolean isUsuarioTestValido() {
    return modoTest && txtUsuarioTest != null && 
           !txtUsuarioTest.getText().trim().isEmpty() &&
           !txtUsuarioTest.getText().equals("Introduce ID usuario");
  }

  public String getUsuarioTest() {
    if (txtUsuarioTest != null && !txtUsuarioTest.getText().isEmpty() &&
        !txtUsuarioTest.getText().equals("Introduce ID usuario")) {
      return txtUsuarioTest.getText().trim();
    }
    return "";
  }

  /**
   * Parsea el parámetro --resolution y devuelve las dimensiones
   * @param resolutionString Formato: "1024x768"
   * @return Dimension object o null si el formato es inválido
   */
  private static Dimension parseResolution(String resolutionString) {
    try {
      String[] parts = resolutionString.split("x");
      if (parts.length == 2) {
        int width = Integer.parseInt(parts[0].trim());
        int height = Integer.parseInt(parts[1].trim());
        return new Dimension(width, height);
      }
    } catch (NumberFormatException e) {
      com.fichajespi.fichajespidestopapp.tools.Logger.error("Formato de resolución inválido: " + resolutionString);
    }
    return null;
  }

  /**
   * This method is called from within the constructor to initialize the form.
   * WARNING: Do NOT modify this code. The content of this method is always
   * regenerated by the Form Editor.
   */

  // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
  private void initComponents() {

    jPanel1 = new javax.swing.JPanel();
    jLabelFichaje = new javax.swing.JLabel();
    jLabel1 = new javax.swing.JLabel();
    jLabelNombre = new javax.swing.JLabel();
    jPanel2 = new javax.swing.JPanel();
    jLabelHora = new javax.swing.JLabel();
    jLabelDate = new javax.swing.JLabel();
    jLabelNumero = new javax.swing.JLabel();

    setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
    setTitle("FichajesPi");
    setBackground(new java.awt.Color(255, 51, 102));
    setLocation(new java.awt.Point(0, 0));
    setLocationByPlatform(true);
    // original para pantalla integrada raspberry pi
    // setMinimumSize(new java.awt.Dimension(480, 320)); 

    setMinimumSize(new java.awt.Dimension(620, 480));
    setName("FichajesPi"); // NOI18N
    setUndecorated(true);
    setResizable(false);

    jPanel1.setBackground(new java.awt.Color(210, 23, 87));

    jLabelFichaje.setFont(new java.awt.Font("sansserif", 0, 30)); // NOI18N
    jLabelFichaje.setForeground(new java.awt.Color(255, 255, 255));
    jLabelFichaje.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    jLabelFichaje.setText("Acerque tarjeta al lector");

    jLabel1.setFont(new java.awt.Font("SansSerif", 0, 35)); // NOI18N
    jLabel1.setForeground(new java.awt.Color(255, 255, 255));
    jLabel1.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    jLabel1.setText("FichajesPi");
    jLabel1.addMouseListener(new java.awt.event.MouseAdapter() {
      public void mouseClicked(java.awt.event.MouseEvent evt) {
        jLabel1MouseClicked(evt);
      }
    });

    jLabelNombre.setFont(new java.awt.Font("sansserif", 0, 35)); // NOI18N
    jLabelNombre.setForeground(new java.awt.Color(255, 255, 255));
    jLabelNombre.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    jLabelNombre.setText("Esperando...");

    jPanel2.setBackground(new java.awt.Color(105, 186, 201));

    jLabelHora.setBackground(new java.awt.Color(255, 255, 204));
    jLabelHora.setFont(new java.awt.Font("sansserif", 1, 34)); // NOI18N
    jLabelHora.setForeground(new java.awt.Color(255, 255, 255));
    jLabelHora.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);
    jLabelHora.setText("00:00");

    jLabelDate.setFont(new java.awt.Font("sansserif", 0, 25)); // NOI18N
    jLabelDate.setForeground(new java.awt.Color(255, 255, 255));
    jLabelDate.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
    jLabelDate.setText("dia");


    javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
    jPanel2.setLayout(jPanel2Layout);

    jPanel2Layout.setHorizontalGroup(
      jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(jPanel2Layout.createSequentialGroup()
        .addGap(23, 23, 23)
        .addComponent(jLabelHora, javax.swing.GroupLayout.PREFERRED_SIZE, 232, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
        .addComponent(jLabelDate, javax.swing.GroupLayout.PREFERRED_SIZE, 202, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addContainerGap(17, Short.MAX_VALUE))
    );

    jPanel2Layout.setVerticalGroup(
      jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(jPanel2Layout.createSequentialGroup()
        .addContainerGap()
        .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
          .addComponent(jLabelHora, javax.swing.GroupLayout.DEFAULT_SIZE, 56, Short.MAX_VALUE)
          .addComponent(jLabelDate, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
    );

    jLabelNumero.setFont(new java.awt.Font("sansserif", 0, 25)); // NOI18N
    jLabelNumero.setForeground(new java.awt.Color(204, 204, 204));
    jLabelNumero.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    jLabelNumero.setText("--");

    javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
    jPanel1.setLayout(jPanel1Layout);
    jPanel1Layout.setHorizontalGroup(
      jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
        .addGap(0, 0, Short.MAX_VALUE)
        .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addGap(22, 22, 22))
      .addGroup(jPanel1Layout.createSequentialGroup()
        .addContainerGap()
        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
          .addComponent(jLabelFichaje, javax.swing.GroupLayout.PREFERRED_SIZE, 465, javax.swing.GroupLayout.PREFERRED_SIZE)
          .addComponent(jLabelNombre, javax.swing.GroupLayout.PREFERRED_SIZE, 465, javax.swing.GroupLayout.PREFERRED_SIZE)
          .addComponent(jLabel1, javax.swing.GroupLayout.PREFERRED_SIZE, 466, javax.swing.GroupLayout.PREFERRED_SIZE)
          .addComponent(jLabelNumero, javax.swing.GroupLayout.PREFERRED_SIZE, 465, javax.swing.GroupLayout.PREFERRED_SIZE))
        .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
    );
    jPanel1Layout.setVerticalGroup(
      jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
        .addContainerGap()
        .addComponent(jLabel1)
        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
        .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
        .addGap(18, 18, 18)
        .addComponent(jLabelNombre)
        .addGap(18, 18, 18)
        .addComponent(jLabelFichaje)
        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 40, Short.MAX_VALUE)
        .addComponent(jLabelNumero)
        .addContainerGap())
    );

    javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
    getContentPane().setLayout(layout);
    layout.setHorizontalGroup(
      layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      //.addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, 480, javax.swing.GroupLayout.PREFERRED_SIZE)
      //.addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
      .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
    );
    layout.setVerticalGroup(
      layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
    );

    pack();
  }// </editor-fold>//GEN-END:initComponents

        private void jLabel1MouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_jLabel1MouseClicked
//Not minimizing anymore
//		setState(JFrame.ICONIFIED);
        }//GEN-LAST:event_jLabel1MouseClicked

  /**
   * @param args the command line arguments
   */
  public static void main(String args[]) {
    /* Set the Nimbus look and feel */
    //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
    /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
     */
    try {
      for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
        if ("Nimbus".equals(info.getName())) {
          javax.swing.UIManager.setLookAndFeel(info.getClassName());
          break;
        }
      }
    } catch (ClassNotFoundException ex) {
      java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
    } catch (InstantiationException ex) {
      java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
    } catch (IllegalAccessException ex) {
      java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
    } catch (javax.swing.UnsupportedLookAndFeelException ex) {
      java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
    }
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>
    //</editor-fold>

    /* Create and display the form */
    java.awt.EventQueue.invokeLater(new Runnable() {
      public void run() {
        boolean modoTest = false;
        Dimension customSize = null;
        
        for (int i = 0; i < args.length; i++) {
          if ("--test".equalsIgnoreCase(args[i])) {
            modoTest = true;
          }
          if ("--resolution".equalsIgnoreCase(args[i]) && i + 1 < args.length) {
            customSize = parseResolution(args[i + 1]);
            if (customSize != null) {
              com.fichajespi.fichajespidestopapp.tools.Logger.info("Resolución personalizada aplicada: " + customSize.width + "x" + customSize.height);
            } else {
              com.fichajespi.fichajespidestopapp.tools.Logger.error("Formato de resolución inválido. Use: --resolution 1024x768");
            }
          }
        }
        
        String backendUrl = BackendConfig.getBackendUrl(args);
        com.fichajespi.fichajespidestopapp.tools.Logger.info("Backend URL utilizada: " + backendUrl);
        
        MainWindow mw = new MainWindow(modoTest, customSize);
        mw.setVisible(true);

        mw.resetScreen();

        CurrentTime updateTime = new CurrentTime(mw);
        updateTime.start();

        CurrentDate updateDate = new CurrentDate(mw);
        updateDate.start();

        new CardReader(mw, modoTest, backendUrl).start();
      }
    });
  }

  public void changeTime(String hora) {
    jLabelHora.setText(hora);
  }

  public void changeDate(String date) {
    jLabelDate.setText(date);
  }

  public void changeNombre(String nombre) {
    jLabelNombre.setText(nombre);
    // Mantener ventana en primer plano cuando se actualiza el nombre (lectura de tarjeta)
    toFront();
    requestFocus();
  }

  public void changeFichaje(String fichaje) {
    jLabelFichaje.setText(fichaje);
    // Mantener ventana en primer plano cuando se actualiza el estado del fichaje
    toFront();
    requestFocus();
  }

  public void changeNumero(String numero) {
    jLabelNumero.setText(numero);
  }

  public void resetScreen() {
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Reseteando pantalla");
    jLabelNombre.setText("Esperando...");
    jLabelFichaje.setText("Acerque su tarjeta...");
    jLabelNumero.setText("");
    
    // Ocultar controles con logging
    if (comboHoras.isVisible()) {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Ocultando selector de horas");
      comboHoras.setVisible(false);
      btnFichar.setVisible(false);
    }
    
    if (timerAutoFichar.isRunning()) {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Deteniendo timer auto-fichar");
      timerAutoFichar.stop();
    }
    
    // Permitir lectura de tarjeta cuando volvemos a la pantalla principal
    setPermitirLecturaTarjeta(true);
    
    // Mantener la ventana siempre en primer plano
    toFront();
    requestFocus();
    
    // Si está en modo test, NO mostrar controles del test en la pantalla principal
    // Los controles del test se manejan mediante ventana emergente
  }

  // Mostrar selector de horas y botón solo para fichaje de entrada
  public void mostrarSelectorHoras(Runnable onFichar) {
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Mostrando selector de horas");
    
    // Bloquear lectura de tarjeta mientras se seleccionan horas
    setPermitirLecturaTarjeta(false);
    
    // PRIMERO: Mantener ventana en primer plano ANTES de cambiar la interfaz
    toFront();
    requestFocus();
    
    this.onFichar = onFichar;
    comboHoras.setSelectedItem("4.00");
    comboHoras.setVisible(true);
    btnFichar.setVisible(true);
    
    // Actualizar texto informativo
    jLabelFichaje.setText("Seleccione horas y pulse Fichar");
    
    // Ocultar controles del modo test si están visibles
    if (modoTest) {
      ocultarControlesTest();
    }
    
    // Asegurar que el timer esté completamente detenido antes de reiniciarlo
    if (timerAutoFichar.isRunning()) {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Deteniendo timer anterior...");
      timerAutoFichar.stop();
    }
    
    // Esperar un momento para asegurar que el timer se ha detenido completamente
    javax.swing.SwingUtilities.invokeLater(() -> {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Iniciando nuevo timer de 30 segundos...");
      timerAutoFichar.restart();
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Timer reiniciado. Tiempo de espera: 30 segundos");
    });
    
    // SEGUNDO: Volver a asegurar que está en primer plano después de los cambios
    javax.swing.SwingUtilities.invokeLater(() -> {
      toFront();
      requestFocus();
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Ventana asegurada en primer plano");
    });
  }

  public void ocultarSelectorHoras() {
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Ocultando selector de horas");
    comboHoras.setVisible(false);
    btnFichar.setVisible(false);
    if (timerAutoFichar.isRunning()) {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Deteniendo timer auto-fichar");
      timerAutoFichar.stop();
    }
    
    // Mantener ventana en primer plano
    toFront();
    requestFocus();
  }

  public double getHorasSeleccionadas() {
    try {
      String valor = (String) comboHoras.getSelectedItem();
      if (valor != null) {
        valor = valor.replace(',', '.');
        return Double.parseDouble(valor);
      }
    } catch (Exception e) {
      // Ignorar
    }
    return 4.0;
  }

  /**
   * Método para verificar si el timer está funcionando correctamente
   */
  public boolean isTimerRunning() {
    return timerAutoFichar != null && timerAutoFichar.isRunning();
  }

  /**
   * Control de lectura de tarjeta para evitar lecturas múltiples
   */
  public boolean isLecturaTarjetaPermitida() {
    return permitirLecturaTarjeta;
  }

  public void setPermitirLecturaTarjeta(boolean permitir) {
    this.permitirLecturaTarjeta = permitir;
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Lectura de tarjeta " + (permitir ? "PERMITIDA" : "BLOQUEADA"));
  }

  /**
   * Muestra mensaje de confirmación de entrada con la hora y estimación
   */
  public void mostrarConfirmacionEntrada(String horaEntrada, double horasEstimadas) {
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Mostrando confirmación de entrada");
    
    // Bloquear lectura de tarjeta durante la confirmación
    setPermitirLecturaTarjeta(false);
    
    // Ocultar selector de horas primero
    comboHoras.setVisible(false);
    btnFichar.setVisible(false);
    
    // Detener timer si está corriendo
    if (timerAutoFichar.isRunning()) {
      timerAutoFichar.stop();
    }
    
    // Actualizar textos de confirmación
    jLabelFichaje.setText("ENTRADA REGISTRADA");
    jLabelNumero.setText(String.format("Hora: %s - Estimación: %.2f horas", horaEntrada, horasEstimadas));
    
    // Mantener ventana en primer plano
    toFront();
    requestFocus();
    
    // Crear timer para volver a la pantalla principal después de 6 segundos
    javax.swing.Timer timerConfirmacion = new javax.swing.Timer(6000, e -> {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Finalizando confirmación de entrada, volviendo a pantalla principal");
      resetScreen();
    });
    timerConfirmacion.setRepeats(false);
    timerConfirmacion.start();
    
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Confirmación mostrada por 6 segundos");
  }

  public void mostrarConfirmacionSalida() {
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Mostrando confirmación de salida");
    
    // Bloquear lectura de tarjeta durante la confirmación
    setPermitirLecturaTarjeta(false);
    
    // Ocultar selector de horas
    comboHoras.setVisible(false);
    btnFichar.setVisible(false);
    
    // Detener timer si está corriendo
    if (timerAutoFichar.isRunning()) {
      timerAutoFichar.stop();
    }
    
    // Actualizar textos de confirmación
    jLabelFichaje.setText("SALIDA REGISTRADA");
    jLabelNumero.setText("¡Hasta la próxima!");
    
    // Mantener ventana en primer plano
    toFront();
    requestFocus();
    
    // Crear timer para volver a la pantalla principal después de 6 segundos
    javax.swing.Timer timerConfirmacion = new javax.swing.Timer(6000, e -> {
      com.fichajespi.fichajespidestopapp.tools.Logger.debug("Finalizando confirmación de salida, volviendo a pantalla principal");
      resetScreen();
    });
    timerConfirmacion.setRepeats(false);
    timerConfirmacion.start();
    
    com.fichajespi.fichajespidestopapp.tools.Logger.debug("Confirmación de salida mostrada por 6 segundos");
  }

  // Variables declaration - do not modify//GEN-BEGIN:variables
  private javax.swing.JLabel jLabel1;
  private javax.swing.JLabel jLabelDate;
  private static javax.swing.JLabel jLabelFichaje;
  private static javax.swing.JLabel jLabelHora;
  private static javax.swing.JLabel jLabelNombre;
  private javax.swing.JLabel jLabelNumero;
  private javax.swing.JPanel jPanel1;
  private javax.swing.JPanel jPanel2;
  // End of variables declaration//GEN-END:variables
}