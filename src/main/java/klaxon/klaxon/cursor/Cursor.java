/**
 * This file is part of Cursor - a mod that _runs_.
 * Copyright (C) 2025 ah-OOG-ah
 *
 * Cursor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Cursor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

package klaxon.klaxon.cursor;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import cpw.mods.fml.common.Mod;
import cpw.mods.fml.common.SidedProxy;
import cpw.mods.fml.common.event.FMLPreInitializationEvent;

@Mod(modid = Cursor.MODID, version = Tags.VERSION, name = "Cursor", acceptedMinecraftVersions = "[1.7.10]")
public class Cursor {

    public static final String MODID = "cursor";
    public static final Logger LOG = LogManager.getLogger(MODID);

    @SidedProxy(clientSide = "klaxon.klaxon.cursor.ClientProxy", serverSide = "klaxon.klaxon.cursor.CommonProxy")
    public static CommonProxy proxy;

    @Mod.EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        proxy.preInit(event);
    }
}
